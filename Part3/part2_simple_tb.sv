// Author: Hemil Shah
// This testbench is not sufficient to test the full correctness of your system, it's just
// a relatively small test to help you get started.

module check_timing();

    logic clk, s_valid_x, s_valid_f, s_ready_x, s_ready_f, m_valid_y, m_ready_y, reset;
    logic signed [7:0] s_data_in_x, s_data_in_f;
    logic signed [20:0] m_data_out_y;
   
    initial clk=0;
    always #5 clk = ~clk;
   

    conv_128_32 dut (.clk(clk), .reset(reset), 
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
    // We will do two tests; each will take 128 values for x and 32 values for f.
    logic [7:0] invals_x[0:255];
    logic [7:0] invals_f[0:63];

    // Generate some test values
    integer z;
    initial begin
        for (z=0; z<256; z=z+1)
            invals_x[z] = z-128;
        for (z=0; z<64; z=z+1)
            invals_f[z] = z-64;
    end

    logic signed [20:0] expectedOut[0:2*(128-32+1)-1] = '{177328, 175776, 174224, 172672, 171120, 169568, 168016, 
        166464, 164912, 163360, 161808, 160256, 158704, 157152, 155600, 154048, 152496, 150944, 149392, 147840, 
        146288, 144736, 143184, 141632, 140080, 138528, 136976, 135424, 133872, 132320, 130768, 129216, 127664, 
        126112, 124560, 123008, 121456, 119904, 118352, 116800, 115248, 113696, 112144, 110592, 109040, 107488, 
        105936, 104384, 102832, 101280, 99728, 98176, 96624, 95072, 93520, 91968, 90416, 88864, 87312, 85760, 
        84208, 82656, 81104, 79552, 78000, 76448, 74896, 73344, 71792, 70240, 68688, 67136, 65584, 64032, 62480, 
        60928, 59376, 57824, 56272, 54720, 53168, 51616, 50064, 48512, 46960, 45408, 43856, 42304, 40752, 39200, 
        37648, 36096, 34544, 32992, 31440, 29888, 28336, -5456, -5984, -6512, -7040, -7568, -8096, -8624, -9152, 
        -9680, -10208, -10736, -11264, -11792, -12320, -12848, -13376, -13904, -14432, -14960, -15488, -16016, 
        -16544, -17072, -17600, -18128, -18656, -19184, -19712, -20240, -20768, -21296, -21824, -22352, -22880, 
        -23408, -23936, -24464, -24992, -25520, -26048, -26576, -27104, -27632, -28160, -28688, -29216, -29744, 
        -30272, -30800, -31328, -31856, -32384, -32912, -33440, -33968, -34496, -35024, -35552, -36080, -36608, 
        -37136, -37664, -38192, -38720, -39248, -39776, -40304, -40832, -41360, -41888, -42416, -42944, -43472, 
        -44000, -44528, -45056, -45584, -46112, -46640, -47168, -47696, -48224, -48752, -49280, -49808, -50336, 
        -50864, -51392, -51920, -52448, -52976, -53504, -54032, -54560, -55088, -55616, -56144};

   
    logic [15:0] x_count;

    /////////////////////////
    // Setting values for input x

    // If our random bit rb is set to 1, and if x_count is within the range of our test vector (invals),
    // we will set s_valid_x to 1.
    always @* begin
       if ((x_count>=0) && (x_count<2*128) && (rb==1'b1)) begin
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
       if ((f_count>=0) && (f_count<32*2) && (rb2==1'b1)) begin
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
        if ((y_count >= 0) && (y_count < 97*2) && (rb3==1'b1))
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

        // wait until all outputs have come out, then finish.
        wait(y_count==97*2);

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
    // the simulation after 1000000 clock cycles.
    initial begin
        repeat(1000000) begin
            @(posedge clk);
        end
        $display("Warning: Output not produced within 1000000 clock cycles; stopping simulation so it doens't run forever");
        $stop;
    end

endmodule
