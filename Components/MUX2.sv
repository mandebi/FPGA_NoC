(* dont_merge *) module MUX2
#(
  parameter DATA_PACKET_SIZE = 10
)
(
    input clk,
	 input reset,
    input [(DATA_PACKET_SIZE-1):0] data_1,
	 input [(DATA_PACKET_SIZE-1):0] data_2,
	 input select,
	 
	 output reg [(DATA_PACKET_SIZE-1):0] out
);

 always@(posedge clk)
 begin
   if(reset)
	   out <='bz;
   else
    begin	
		  if(select===0)
			  out <= data_1;
		  else
		   if(select===1)  
			  out <= data_2;
		   else
		     if(select===1'bx)
		        out <='bx;
			 else
			   if(select===1'bz)
	     	      out <='bz;
 	 end 
 end

endmodule 