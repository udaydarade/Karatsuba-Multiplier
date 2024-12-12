

module mult_16(X, Y, Z);
input [15:0] X;
input [15:0] Y;
output [31:0] Z;

assign Z = X*Y;

endmodule


/*32-bit Karatsuba multipliction using a single 16-bit module*/

module iterative_karatsuba_32_16(clk, rst, enable, A, B, C);
    input clk;
    input rst;
    input [31:0] A;
    input [31:0] B;
    output [63:0] C;
    
    input enable;
    
    
    wire [1:0] sel_x;
    wire [1:0] sel_y;
    
    wire [1:0] sel_z;
    wire [1:0] sel_T;
    
    
    wire done;
    wire en_z;
    wire en_T;
    
    /*
    reg [32:0] T;
    reg [63:0] Z;
    
    wire [31:0] t2;         
    wire [32:0] t3;
    wire [32:0] t4;
    
 
    // Mux for Z reg
   always@(posedge clk) begin
        if (rst) begin
            Z <= 64'b0;
        end
        if (en_z) begin
            if(sel_z == 2'b01) begin        
                    Z <= C + t2;
            end
            else if (sel_z == 2'b10) begin
                    Z <= C + (t2 << 32);
            end
            else if (sel_z == 2'b11) begin
                    Z <= C + (t4 << 16);
            end
            else begin
                    Z <= 64'b0;
            end
        end
    end
    
   // Mux for T reg
    always@(posedge clk) begin
        if (rst) begin
            T <= 0;
        end 
        if (en_T) begin
            if(sel_T == 2'b01) begin
                T <= t3 + t2;
            end
            else if (sel_T == 2'b10) begin
                T <= t3 + t2;
            end
            else if (sel_T == 2'b11) begin
                T <= t3;
            end
            else begin
                T <= 64'b0;
            end
        end

    end   
    */
    
    
    wire [32:0] h1;
    wire [32:0] h2;
    wire [63:0] g1;
    wire [63:0] g2;
    
    assign C = g2;
    reg_with_enable #(.N(63)) Z(.clk(clk), .rst(rst), .en(en_z), .X(g1), .O(g2) );
    reg_with_enable #(.N(32)) T(.clk(clk), .rst(rst), .en(en_T), .X(h1), .O(h2) );
    
    iterative_karatsuba_datapath dp(.clk(clk), .rst(rst), .X(A), .Y(B), .Z(g2), .T(h2), .sel_x(sel_x), .sel_y(sel_y), .sel_z(sel_z), .sel_T(sel_T), .en_z(en_z), .en_T(en_T), .done(done), .W1(g1), .W2(h1));
    iterative_karatsuba_control control(.clk(clk),.rst(rst), .enable(enable), .sel_x(sel_x), .sel_y(sel_y), .sel_z(sel_z), .sel_T(sel_T), .en_z(en_z), .en_T(en_T), .done(done));
    
endmodule

module iterative_karatsuba_datapath(clk, rst, X, Y, T, Z, sel_x, sel_y, en_z, sel_z, en_T, sel_T, done, W1, W2);
    input clk;
    input rst;
    input [31:0] X;
    input [31:0] Y;
    input [32:0] T;
    input [63:0] Z;
    

    input [1:0] sel_x;
    input [1:0] sel_y;
    
    input en_z;
    input [1:0] sel_z;
    input en_T;
    input [1:0] sel_T;
    
    input done;
    
    
    output [63:0] W1;
    output [32:0] W2;
    reg [63:0] w1;
    reg [32:0] w2;
    
    reg [15:0] temp0;       // 16-bit
    reg [15:0] temp1;       // 16-bit
    reg [31:0] temp2;       // 32-bit 
    
    wire [15:0] t0;         // 16-bit
    wire [15:0] t1;         // 16-bit
    wire [31:0] t2;         // 32-bit
    wire [32:0] t4;
    
    wire cin1;
    wire cin2;


    wire [(32/2)-1:0] Xh_P_Xl;
    wire [(32/2)-1:0] Yh_P_Yl;
    
    wire [(32/2)-1:0] Xh_P_Xl_tmp;
    wire [(32/2)-1:0] Yh_P_Yl_tmp;
    
    wire [(32/2)-1:0] comp_Xh_P_Xl;
    wire [(32/2)-1:0] comp_Yh_P_Yl;    
    
    
    wire [32-1:0] comp_t11;
    wire [32-1:0] t11_tmp;
    
    wire select;

    assign cin1 = 0;
    assign cin2 = 0;
    
    
    // The subtractor and other associated units 
    
    subtract_Nbit #(.N(16)) sub1 (.a(X[15:0]), .b(X[31:16]), .cin(cin1), .S(Xh_P_Xl_tmp), .ov(ov1), .cout_sub(cout_sub1));  // N/2-bit subtractor with (N/2)-bit result
    subtract_Nbit #(.N(16)) sub2 (.a(Y[31:16]), .b(Y[15:0]), .cin(cin2), .S(Yh_P_Yl_tmp), .ov(ov2), .cout_sub(cout_sub2));  // N/2-bit subtractor with (N/2)-bit result
 
     // Take the absolute values for multiplication
    Complement2_Nbit #(.N(16)) comp1 (.a(Xh_P_Xl_tmp), .c(comp_Xh_P_Xl), .cout_comp());
    Complement2_Nbit #(.N(16)) comp2 (.a(Yh_P_Yl_tmp), .c(comp_Yh_P_Yl), .cout_comp());
    assign Xh_P_Xl = cout_sub1 ? Xh_P_Xl_tmp: comp_Xh_P_Xl;
    assign Yh_P_Yl = cout_sub2 ? Yh_P_Yl_tmp: comp_Yh_P_Yl;

    
    // Muxes for the multiplier unit
    always@(X[31:16], X[15:0], temp0, sel_x) begin
    case(sel_x)
        2'b01: temp0 = X[15:0];   
        2'b10: temp0 = X[31:16];  
        2'b11: temp0 = Xh_P_Xl; 
        default: temp0 = 16'b0;        
    endcase
    end

    always@(Y[31:16], Y[15:0], temp1, sel_y) begin
        case(sel_y)
            2'b01: temp1 = Y[15:0]; 
            2'b10: temp1 = Y[31:16]; 
            2'b11: temp1 = Yh_P_Yl ; 
            default: temp1 = 16'b0;
        endcase
    end        

    // The multiplier
    assign t0 = temp0;
    assign t1 = temp1;    
    
    mult_16 m16 (.X(t0), .Y(t1), .Z(t2)); 
  
   
     
    assign select = cout_sub1 ^ cout_sub2;
    assign t4 = select? (T - t2) : (T + t2); 
   
   // Adders and shifters (note that we can also optimize this part by reusing the same unit for subtraction and addition. But it 
   // will make the datapath and controller more complex)
   wire [63:0] w1_temp;
   wire [32:0] w2_temp;
   wire [63:0] t5;
   wire [63:0] t6;
   reg [63:0] t7;
   reg [32:0] t8;
   
   adder_Nbit #(.N(64)) addr1 (.a(Z), .b(t7), .cin(1'b0), .S(w1_temp), .cout());
   Left_barrel_Nbit #(.N(64)) shift1 (.a({32'b0,t2}), .n(6'b100000), .c(t5));
   Left_barrel_Nbit #(.N(64)) shift2 (.a({31'b0,t4}), .n(6'b010000), .c(t6));
   
   //assign t5 = (t2 << 32);
   //assign t6 = (t4 << 16);
   
   
   always@(*) begin
        case(sel_z)
            2'b01: t7 = {32'b0,t2}; 
            2'b10: t7 = t5; 
            2'b11: t7 = t6; 
            default: t7 = 64'b0;        
        endcase
   end
 
   
   always@(*) begin
        case(sel_T)
            2'b01: t8 = t2; 
            2'b10: t8 = t2; 
            2'b11: t8 = 33'b0; 
            default: t8 = 33'b0;        
        endcase
   end   
   adder_Nbit #(.N(33)) addr2 (.a(T), .b(t8), .cin(1'b0), .S(w2_temp), .cout());
   
   
   // Muxes for the register input
   /* always@(sel_z, Z, t2, t4) begin
        case(sel_z)
            2'b01: w1 = Z + t2; 
            2'b10: w1 = Z + (t2 << 32); 
            2'b11: w1 = Z + (t4 << 16); 
            default: w1 = 64'b0;
        endcase
    end
    */
 
    /*
    always@(sel_T, T, t2) begin
        case(sel_T)
            2'b01: w2 = T + t2; 
            2'b10: w2 = T + t2; 
            2'b11: w2 = T; 
            default: w2 = 33'b0;
        endcase
    end     
    */
 
    //assign W1 = w1;
    //assign W2 = w2;
    assign W1 = w1_temp;
    assign W2 = w2_temp;

endmodule


module iterative_karatsuba_control(clk,rst, enable, sel_x, sel_y, sel_z, sel_T, en_z, en_T, done);
    input clk;
    input rst;
    input enable;
    
    output reg [1:0] sel_x;
    output reg [1:0] sel_y;
    
    output reg [1:0] sel_z;
    output reg [1:0] sel_T;    
    
    output reg en_z;
    output reg en_T;
    
    
    output reg done;
    
    reg [5:0] state, nxt_state;
    parameter S0 = 6'b000001;
    parameter S1 = 6'b000010;
    parameter S2 = 6'b000100;
    parameter S3 = 6'b001000;
    parameter S4 = 6'b010000;

    always @(posedge clk) begin
        if (rst) begin
            state <= S0;
        end
        else if (enable) begin
            state <= nxt_state;
        end
    end
    

    always@(*) begin
        case(state) 
            S0: 
                begin
                    sel_x = 2'b00;
                    sel_y = 2'b00;
                    sel_z = 2'b00;
                    sel_T = 2'b00;                    
                    done = 1'b0;
                    en_z = 1'b0;
                    en_T = 1'b0;
                    nxt_state = S1; 
                end
            S1:
                begin
                    sel_x = 2'b01;
                    sel_y = 2'b01;
                    sel_z = 2'b01;
                    sel_T = 2'b01;                                        
                    done = 1'b0;
                    en_z = 1'b1;
                    en_T = 1'b1;                    
                    nxt_state = S2; 
                end
            S2:
                begin
                    sel_x = 2'b10;
                    sel_y = 2'b10;
                    sel_z = 2'b10;
                    sel_T = 2'b10;                                        
                    done = 1'b0;
                    en_z = 1'b1;
                    en_T = 1'b1;                      
                    nxt_state = S3; 
                end
            S3:
                begin
                    sel_x = 2'b11;
                    sel_y = 2'b11;
                    sel_z = 2'b11;
                    sel_T = 2'b11;                                        
                    done = 1'b0;
                    en_z = 1'b1;
                    en_T = 1'b1;                        
                    nxt_state <= S4; 
                end
            S4:
                begin
                    sel_x = 2'b00;
                    sel_y = 2'b00;
                    sel_z = 2'b00;
                    sel_T = 2'b00;                                        
                    done = 1'b1;
                    en_z = 1'b0;
                    en_T = 1'b0;                        
                    nxt_state <= S4; 
                end               
            default: 
                begin
                    sel_x = 2'b00;
                    sel_y = 2'b00;
                    sel_z = 2'b00;
                    sel_T = 2'b00;                                        
                    done = 1'b0;
                    en_z = 1'b0;
                    en_T = 1'b0;                      
                    nxt_state = S1; 
                end            
        endcase
        
    end

endmodule


module reg_with_enable #(parameter N = 32) (clk, rst, en, X, O );
    input [N:0] X;
    input clk;
    input rst;
    input en;
    output [N:0] O;
    
    reg [N:0] R;
    
    always@(posedge clk) begin
        if (rst) begin
            R <= {N{1'b0}};
        end
        if (en) begin
            R <= X;
        end
    end
    assign O = R;
endmodule







/*-------------------Supporting Modules--------------------*/


module full_adder(a, b, cin, S, cout);
input a;
input b;
input cin;
output S;
output cout;

assign S = a ^ b ^ cin;
assign cout = (a&b) ^ (b&cin) ^ (a&cin);

endmodule


module check_subtract (A, B, C);
 input [7:0] A;
 input [7:0] B;
 output [8:0] C;
 
 assign C = A - B; 
endmodule



/* N-bit RCA adder (Unsigned) */
module adder_Nbit #(parameter N = 32) (a, b, cin, S, cout);
input [N-1:0] a;
input [N-1:0] b;
input cin;
output [N-1:0] S;
output cout;

wire [N:0] cr;  

assign cr[0] = cin;


generate
    genvar i;
    for (i = 0; i < N; i = i + 1) begin
        full_adder addi (.a(a[i]), .b(b[i]), .cin(cr[i]), .S(S[i]), .cout(cr[i+1]));
    end
endgenerate    


assign cout = cr[N];

endmodule


module Not_Nbit #(parameter N = 32) (a,c);
input [N-1:0] a;
output [N-1:0] c;

generate
genvar i;
for (i = 0; i < N; i = i+1) begin
    assign c[i] = ~a[i];
end
endgenerate 

endmodule


/* 2's Complement (N-bit) */
module Complement2_Nbit #(parameter N = 32) (a, c, cout_comp);

input [N-1:0] a;
output [N-1:0] c;
output cout_comp;

wire [N-1:0] b;
wire ccomp;

Not_Nbit #(.N(N)) compl(.a(a),.c(b));
adder_Nbit #(.N(N)) addc(.a(b), .b({ {N-1{1'b0}} ,1'b1 }), .cin(1'b0), .S(c), .cout(ccomp));

assign cout_comp = ccomp;

endmodule


/* N-bit Subtract (Unsigned) */
module subtract_Nbit #(parameter N = 32) (a, b, cin, S, ov, cout_sub);

input [N-1:0] a;
input [N-1:0] b;
input cin;
output [N-1:0] S;
output ov;
output cout_sub;

wire [N-1:0] minusb;
wire cout;
wire ccomp;

Complement2_Nbit #(.N(N)) compl(.a(b),.c(minusb), .cout_comp(ccomp));
adder_Nbit #(.N(N)) addc(.a(a), .b(minusb), .cin(1'b0), .S(S), .cout(cout));

assign ov = (~(a[N-1] ^ minusb[N-1])) & (a[N-1] ^ S[N-1]);
assign cout_sub = cout | ccomp;

endmodule



/* n-bit Left-shift */

module Left_barrel_Nbit #(parameter N = 32)(a, n, c);

input [N-1:0] a;
input [$clog2(N)-1:0] n;
output [N-1:0] c;


generate
genvar i;
for (i = 0; i < $clog2(N); i = i + 1 ) begin: stage
    localparam integer t = 2**i;
    wire [N-1:0] si;
    if (i == 0) 
    begin 
        assign si = n[i]? {a[N-t:0], {t{1'b0}}} : a;
    end    
    else begin 
        assign si = n[i]? {stage[i-1].si[N-t:0], {t{1'b0}}} : stage[i-1].si;
    end
end
endgenerate

assign c = stage[$clog2(N)-1].si;

endmodule



