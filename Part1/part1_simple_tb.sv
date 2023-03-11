// Author: Hemil Shah
// This testbench is not sufficient to test the full correctness of your system, it's just
// a relatively small test to help you get started.

module check_timing();

    logic clk, s_valid_x, s_valid_f, s_ready_x, s_ready_f, m_valid_y, m_ready_y, reset;
    logic signed [7:0] s_data_in_x, s_data_in_f;
    logic signed [17:0] m_data_out_y;
   
    initial clk=0;
    always #5 clk = ~clk;
   

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
    // We will do two tests; each will take 8 values for x and 4 values for f.
    logic [7:0] invals_x[0:15] = '{10,-20,30,-40,50,60,70,80, -90, 100, -110, 120, -50, 40, 30, -20};
    logic [7:0] invals_f[0:7] = '{10,20,-30,40, -50, -60, 70, 80}; 

    logic signed [17:0] expectedOut[0:9] = '{-2800, 3600, 400, 1600, 2800, 400, 6000, -2000, 2200, 600};
    
    logic [15:0] x_count;

    /////////////////////////
    // Setting values for input x

    // If our random bit rb is set to 1, and if x_count is within the range of our test vector (invals),
    // we will set s_valid_x to 1.
    always @* begin
       if ((x_count>=0) && (x_count<16) && (rb==1'b1)) begin
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
    
    logic [15:0] f_count;
    always @* begin
       if ((f_count>=0) && (f_count<8) && (rb2==1'b1)) begin
          s_valid_f=1;
       end
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


    /////////////////////////////
    // code to receive the output values

    // we will use another random bit (rb3) to determine if we can assert m_ready_y.
    logic [15:0] y_count;
    always @* begin
        if ((y_count >= 0) && (y_count < 10) && (rb3==1'b1))
            m_ready_y = 1;
        else
            m_ready_y = 0;
    end

    always @(posedge clk) begin
        if (m_ready_y && m_valid_y) begin
            if (m_data_out_y !== expectedOut[y_count]) 
                $display("ERROR:   y[%d] = %d    expected output = %d", y_count, m_data_out_y, expectedOut[y_count]);
            else
                $display("SUCCESS: y[%d] = %d", y_count, m_data_out_y);
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

        // wait until the outputs have come out, then finish.
        wait(y_count==10);

        // Now we're done!
        
        // Just as a test: wait another 100 cycles and make sure the DUT doesn't assert m_valid again.
        // It shouldn't, because the system finished the inputs it was given, so it should be waiting
        // for new input data.
        repeat(100) begin
            @(posedge clk);
            if (m_valid_y == 1)
                $display("ERROR: DUT asserted m_valid_y incorrectly");
        end
        
        $finish;
    end


    // This is just here to keep the testbench from running forever in case of error.
    // In other words, if your system never produces three outputs, this code will stop 
    // the simulation after 1000 clock cycles.
    initial begin
        repeat(10000) begin
            @(posedge clk);
        end
        $display("Warning: Output not produced within 10000 clock cycles; stopping simulation so it doens't run forever");
        $stop;
    end

endmodule
