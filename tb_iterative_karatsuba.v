`timescale 1ns/1ps
module tb_iterative_karatsuba;
parameter N = 32;

reg clk;
reg rst;
reg enable;

reg [N-1:0] X;
reg [N-1:0] Y;

wire [(2*N - 1):0] Z;

reg [1:0] sel_x;
reg [1:0] sel_y;
reg  en_xhyh;
reg  en_xlyl;
reg  en_inter;

reg done;

reg [N:0] i;
reg [N:0] j;

always begin
    #5 clk = ~clk;
end

initial begin
    $display("time\t, clk\t rst\t, X\t, Y\t, Z\t ");
    $monitor ("%g\t %b\t   %b\t     %d\t      %d\t      %d\t   ", $time, clk, rst, X, Y, Z);	

    clk = 1;
    rst = 0;

    /*
    #10 rst = 1;
    #10 rst = 0;
    
    
    #10 X = 4294967295;
       Y = 255;
        enable = 1;
    
    #100 enable = 1'b0;
    */
    
    
    #10 rst = 1;
    #10 rst  = 0;
    
    //#10 X = 4294967295;
    //    Y = 255;
    #10 X = 10;
        Y = 12;
        enable = 1'b1;   
        
        
    #50 rst = 1;
        enable = 1'b0;
        
    for (i=0; i<10; i=i+1) begin
        for (j=0; j<10; j=j+1) begin
            X = i; 
            Y = 12;
            enable = 1'b1; 
            #50 
            if (Z != X*Y) begin
                $display("ERROR");
                $monitor("%d\t", Z);
                $finish;
            end 
            #50 rst = 1;
            enable = 1'b0;
            #10 rst = 0;
            
        end    
    end                
    
    //#10 rst = 0;
    //#10 X = 334;
    //    Y = 324;    
    //    enable = 1'b1;
        
    #100 enable = 1'b0;
    /*
    sel_x = 2'b01;
    sel_y = 2'b01;
    en_xhyh = 1'b0;
    en_xlyl = 1'b0;
    en_inter = 1'b0;
    done = 1'b0;  

    #10
    sel_x = 2'b10;
    sel_y = 2'b10;
    en_xhyh = 1'b1;
    en_xlyl = 1'b0;
    en_inter = 1'b0;    
    done = 1'b0;  
        

    #10
    sel_x = 2'b11;
    sel_y = 2'b11;
    en_xhyh = 1'b0;
    en_xlyl = 1'b1;
    en_inter = 1'b0;      
    done = 1'b0;    

    #10
    sel_x = 2'b00;
    sel_y = 2'b00;
    en_xhyh = 1'b0;
    en_xlyl = 1'b0;
    en_inter = 1'b1;
    done = 1'b0;  
    
    #10
    sel_x = 2'b00;
    sel_y = 2'b00;
    en_xhyh = 1'b0;
    en_xlyl = 1'b0;
    en_inter = 1'b0;
    done = 1'b0;      
    
    #10
    done = 1'b1;    
    #10
    done = 1'b0; 
    */
    
    
    /*
    #10
    #10 X = 79;
    #10 Y = 555;
    
    #100
    //#10 X = 4294967295;
    //#10 Y = 4294967295;
    #10 X = 65535;
    #10 Y = 5;
    */
    
    #100
    #500 $finish;
end



//simple_karatsuba  #(.N(N)) dut (.X(X), .Y(Y), .Z(Z));

//iterative_karatsuba_32_16  dut (.A(X), .B(Y), .C(Z));

//iterative_karatsuba_datapath dp(.clk(clk), .rst(rst), .X(X), .Y(Y), .sel_x(sel_x), .sel_y(sel_y), .en_xhyh(en_xhyh), .en_xlyl(en_xlyl), .en_inter(en_inter), .done(done), .result(Z));

iterative_karatsuba_32_16 ik(.clk(clk), .rst(rst), .enable(enable), .A(X), .B(Y), .C(Z) );


initial begin
    $dumpfile("iterative_karatsuba.vcd");
    $dumpvars(0,tb_iterative_karatsuba);
end

endmodule

