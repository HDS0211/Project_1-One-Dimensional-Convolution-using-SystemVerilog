
// Author: Hemil Shah

// This testbench does the following:
//    - opens file random_in_f.hex and random_in_x.hex (input values to simulate) and stores 
//      their values in arrays
//    - opens expected_out.hex (expected output values) and stores its values in an array
//    - on each clock cycle, randomly picks values for valid and ready control signals
//    - uses these random control values to decide when to give new input and receive output
//    - automatically check expected output is correct

module tbench1();

    parameter  NUMITS     = 100000, N = 8, M = 4;
    localparam NUMXVALS   = N*NUMITS;
    localparam NUMFVALS   = M*NUMITS;
    localparam NUMOUTVALS = (N-M+1)*NUMITS;

    logic clk, s_valid_x, s_valid_f, s_ready_x, s_ready_f, m_valid_y, m_ready_y, reset;
    logic signed [7:0] s_data_in_x, s_data_in_f;
    logic signed [17:0] m_data_out_y;

    initial clk=0;
    always #5 clk = ~clk;

    // Instantiate DUT
    conv_8_4 dut (.clk(clk), .reset(reset), 
                  .s_data_in_x(s_data_in_x),   .s_valid_x(s_valid_x), .s_ready_x(s_ready_x),
                  .s_data_in_f(s_data_in_f),   .s_valid_f(s_valid_f), .s_ready_f(s_ready_f),
                  .m_data_out_y(m_data_out_y), .m_valid_y(m_valid_y), .m_ready_y(m_ready_y));


    //////////////////////////////////////////////////////////////////////////////////////////////////
    // code to feed some test inputs

    // rb, rb2, and rb3 represent random bits. Each clock cycle, we will randomize the value of these bits.
    // We will use rb to determine when to let our testbench send new x data. (When rb==0, we will not send valid data)
    // We will use rb2 to determine when to let our testbench send new f data. (When rb2==0, we will not send valid data)
    // We will use rb3 to determine when to let our testbench receive new y data. (When rb3==0, we will not receive results)
    logic rb, rb2, rb3;
    integer ignore;
    always begin
       @(posedge clk);
       #1;
       ignore = std::randomize(rb, rb2, rb3); // randomize rb
    end


    // Put our test data into these arrays. These are the values we will feed as input into the system.
    logic signed [7:0] invals_x[NUMXVALS-1:0], invals_f[NUMFVALS-1:0];      
    initial $readmemh("random_in_x.hex", invals_x); 
    initial $readmemh("random_in_f.hex", invals_f); 

    // Store the expected values in another array
    logic signed [17:0] expectedOut[NUMOUTVALS-1:0];
    initial $readmemh("expected_out.hex", expectedOut);
        
    logic [31:0] x_count;

    // If our random bit rb is set to 1, and if x_count is within the range of our test vector (invals),
    // we will set s_valid_x to 1.
    always @* begin
       if ((x_count>=0) && (x_count<NUMXVALS) && (rb==1'b1)) begin
          s_valid_x=1;
       end
       else
          s_valid_x=0;
    end

    // If s_valid_x is set to 1, we will put data on s_data_in_x.
    // If s_valid_x is 0, we will put an X on the data_in to test that your system does not 
    // process the invalid input.
    always @* begin
       if (s_valid_x == 1)
          s_data_in_x = invals_x[x_count];
       else
          s_data_in_x = 'x;
    end

    // If we set s_valid_x and s_ready_x asserted on this clock edge, we will increment x_count just after
    // this clock edge.
    always @(posedge clk) begin
       if (s_valid_x && s_ready_x)
          x_count <= #1 x_count+1;
    end
  
    ////////////////////////
    // Setting values for input f

    // Same logic but with f_count and s_data_in_f
    
    logic [31:0] f_count;
    always @* begin
       if ((f_count>=0) && (f_count<NUMFVALS) && (rb2==1'b1)) 
          s_valid_f=1;
       else
          s_valid_f=0;
    end

    always @* begin
       if (s_valid_f == 1)
          s_data_in_f = invals_f[f_count];
       else
          s_data_in_f = 'x;
    end

    always @(posedge clk) begin
       if (s_valid_f && s_ready_f)
          f_count <= #1 f_count+1;
    end


    ////////////////////////////////////////////////////////////////////////////////////////
    // code to receive the output values


    // we will use another random bit (rb3) to determine if we can assert m_ready_y.
    logic [31:0] y_count;
    always @* begin
        if ((y_count >= 0) && (y_count < NUMOUTVALS) && (rb3==1'b1))
            m_ready_y = 1;
        else
            m_ready_y = 0;
    end
   
    integer errors=0;

    always @(posedge clk) begin
        if (m_ready_y && m_valid_y) begin
            if (m_data_out_y !== expectedOut[y_count]) begin
                $display("ERROR:   y[%d] = %d    expected output = %d", y_count, m_data_out_y, expectedOut[y_count]);
                errors = errors+1;
            end
            y_count = y_count+1; 
        end 
    end

    ////////////////////////////////////////////////////////////////////////////////

    initial begin       
        x_count=0; f_count=0; y_count=0;
        
        // Before first clock edge, initialize
        m_ready_y = 0; 
        reset = 0;

        // reset
        @(posedge clk); #1; reset = 1; 
        @(posedge clk); #1; reset = 0;

        $display("Starting simulation. This may take a few seconds.");
       
        wait(y_count==NUMOUTVALS);

        $display("\n------------- simulation finished ------------------");
        $display("Simulated ", NUMITS, " iterations; ", NUMOUTVALS, " outputs");
        if (errors > 0) 
            $display("Detected ", errors, " errors");
        else
            $display("No errors detected");
        $display("----------------------------------------------------\n");

        
        $finish;
    end


    // This is just here to keep the testbench from running forever in case of error.
    // In other words, if your system never produces the expected outputs, this code will stop 
    // the simulation after NUMITS*200 clock cycles.
    initial begin
        repeat(NUMITS*200) begin
            @(posedge clk);
        end
        
        $display("Warning: Output not produced within", NUMITS*200, " clock cycles; stopping simulation so it doens't run forever");
        $display("So far simulated ", y_count, " outputs");
        $stop;
    end

endmodule

