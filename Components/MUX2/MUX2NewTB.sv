`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2021 08:37:43 PM
// Design Name: 
// Module Name: MUX2NewTB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MUX2NewTB();
  localparam DATA_PACKET_SIZE = 4;
  localparam period = 2;
  
  logic clk;
  logic reset;
  logic [(DATA_PACKET_SIZE-1):0] data_1;
  logic [(DATA_PACKET_SIZE-1):0] data_2;
  logic select;
 
  logic [(DATA_PACKET_SIZE-1):0] out;
  
  
  MUX2 
   #(.DATA_PACKET_SIZE(DATA_PACKET_SIZE))
  DUT(
     .clk(clk),
     .reset(reset),
     .data_1(data_1),
     .data_2(data_2),
     .select(select),
     .out(out)
  );
  
  function logic [(DATA_PACKET_SIZE-1):0] checkMux(logic select, logic [(DATA_PACKET_SIZE-1):0] data_1, logic [(DATA_PACKET_SIZE-1):0] data_2 );
    if(select === 0)
       return data_1;
    else
     if(select === 1)
       return data_2;
     else
      if(select === 1'bx)
        return 'bx; 
      else
        if(select === 1'bz)
           return 'bz;  
  endfunction
  
  initial begin
    $dumpfile("MUX2.vcd");
    $dumpvars(1, MUX2NewTB); 
  end
  
  initial begin
    clk <= 0;
    reset <= 0;
    data_1 <= 0;
    data_2 <= 0;
    select <= 0;
  end
  
  always begin
    #(period/2) clk <= ~clk;
  end

  always@(posedge clk) begin //Here we test all possible input combinations without x and z
       #(period)
      if( (data_1 == (2**DATA_PACKET_SIZE -1))&&(data_2 == (2**DATA_PACKET_SIZE -1)) ) begin
            if(select == 0)
               select <= 1;
               
            if(select == 1)
               select <= 1'bz;
               
            if(select === 1'bz)
               select <= 1'bx;    
             
            if(select === 1'bx)
                 $finish;   
               
            data_1 <= 0;
            data_2 <= 0;
      end
          
      if( data_1 < (2**DATA_PACKET_SIZE -1) )    
          data_1 <= data_1 + 1;
      
      if( data_1 == (2**DATA_PACKET_SIZE -1) )
         if( data_2 < (2**DATA_PACKET_SIZE -1) )
             data_2 <= data_2 + 1;
            
      
  end 
  
   always@(posedge clk) begin
   
      #(period)
      assert(out===checkMux(select, data_1, data_2) ) $display("[time=%0t] TEST PASSED for inputs select =%0d -- data_1=%0d -- data_2=%0d ### out=%0d",$time,select,data_1,data_2,out );
      else
        $display("[time=%0t] TEST FAILED for inputs select =%0d -- data_1=%0d -- data_2=%0d ### out=%0d instead of %0d",$time,select,data_1,data_2, out,checkMux(select, data_1, data_2)); 
          
   end

endmodule
