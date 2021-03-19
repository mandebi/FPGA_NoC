`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2021 10:57:21 PM
// Design Name: 
// Module Name: DEMUX2NewTB
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
// Inspired from: https://www.chipverify.com/systemverilog/systemverilog-testbench-example-2
//////////////////////////////////////////////////////////////////////////////////
localparam DATA_PACKET_SIZE  = 16;
localparam NUM_TEST_CASES  = 100;

/*       ### DEMUX_ITEM CLASS ### */

class demux_item; 
/*
Transactional object that will be used in the environment
to initiate new transactions and capture transactions at 
DUT interface
*/
 rand logic [(DATA_PACKET_SIZE-1):0] data_1;
  logic [(DATA_PACKET_SIZE-1):0] out_1;
  logic [(DATA_PACKET_SIZE-1):0] out_2;
 rand logic select;
 
 /*
 Function that prints the content of the data packet for easy tracking in the log file
 */
 function void print(string tag);
   $display("[TRANSACTION_ITEM] T=%0t -- %s -- data_1=0x%0h -- select=%0d -- out_1=0x%0h -- out_2=0x%0h",$time,tag, data_1,select,out_1,out_2);
 endfunction
endclass


/*       ### GENERATOR CLASS ### */

class generator;
/*
 Class that generates random number of transactions
 with random data content to the DUT
*/
mailbox drv_mbx;
event drv_done;
int num = NUM_TEST_CASES;//we can make this random with $urandom_range();

task run();
  $display("  T=%0t [Generator] starting ... \n",$time);
  for(int i = 0; i < num; i++) begin
    demux_item item = new;
    item.randomize();
    $display("\n  ----> T=%0t [Generator] Loop:%0d/%0d -- item.data_1=0x%0h -- item.select=0x%0h \n",$time,i,num,item.data_1,item.select);
    drv_mbx.put(item);
    @(drv_done);
  end
  $display("  ----> T=%0t [Generator] Done Generating %0d items",$time, num);
endtask
endclass

/*       ### DRIVER CLASS ### */
class driver;
 virtual demux_if vif;
 event drv_done;
 mailbox drv_mbx;
 
 task run();
   $display("  T=%0t [Driver] starting ... ",$time);
   
   @(posedge vif.clk);
   
   /*
   We get a new transaction at each new clock cycle then assign the packet
   then assign the packet to the interface. 
   */
   forever begin
     demux_item item;
     
     //$display("  T=%0t [Driver] waiting for item ... ",$time);
     drv_mbx.get(item);
     item.print("Driver");
     vif.data_1 = item.data_1;
     vif.select = item.select;
     vif.out_1 = item.out_1;
     vif.out_2 = item.out_2;
     //$display("   >> [Driver] T=%0t RECEIVED  -- data_1=0x%0h -- select=%0d -- out_1=0x%0h -- out_2=0x%0h",$time,item.data_1,item.select,item.out_1,item.out_2);
     /*
      After the transfer, we raise the done event
     */
     @(posedge vif.clk);
       ->drv_done;
   end
 endtask 
endclass


/*       ### MONITOR CLASS ### */
class monitor;
 virtual demux_if vif;
 mailbox scb_mbx;
 semaphore sema4;

 function new();
  sema4 = new(1);
 endfunction

 task run();
  $display("  T=%0t [Monitor] starting ... ",$time);
  
  /*We use 2 threads*/
  fork
     sample_port("Thread0");
     sample_port("Thread1");
     sample_port("Thread3");
     sample_port("Thread4");
   join  
 endtask

  task sample_port(string tag);
   /*
    This task monitors the interface for a complete transaction and store
    results into the mailbox that is shared with the scoreboard
   */
   forever begin 
       @(posedge vif.clk);
       if(!vif.reset)begin
         demux_item item = new;
         sema4.get();
         item.select = vif.select;
         item.data_1 = vif.data_1;
         item.out_1 = vif.out_1;
         item.out_2 = vif.out_2;
         //$display("  ## T=%0t [Monitor] %s Before ... -- data_1=0x%0h -- select=%0d  -- out_1=0x%0h -- out_2=0x%0h",$time,tag, item.data_1,item.select,item.out_1,item.out_2);
       
         @(posedge vif.clk);//wait 1 clock cycle
          
         //sema4.put();
         item.out_1 = vif.out_1;
         item.out_2 = vif.out_2;
         $display("  ## T=%0t [Monitor] %s After 1 cycle ... -- data_1=0x%0h -- select=%0d  -- out_1=0x%0h -- out_2=0x%0h",$time,tag, item.data_1,item.select,item.out_1,item.out_2);
         sema4.put();  
         scb_mbx.put(item);
         //item.print({"Monitor_",tag});
      end   
   end
  endtask
endclass


/*    ### SCOREBOARD CLASS ### */
class scoreboard;
mailbox scb_mbx;

task run();
 $display("  T=%0t [Scoreboard] starting ... ",$time);
 forever begin
   demux_item item;
   scb_mbx.get(item);
   
   
   //add controls to check X and Z
   if((item.select === 0 && item.out_1 !== item.data_1) || (item.select === 1 && item.out_2 !== item.data_1) )
     $display(" *** T=%0t [Scoreboard] ERROR! select=%0d -- data_1=0x%0h -- out_1=0x%0h -- out_2=0x%0h ",$time,item.select,item.data_1,item.out_1, item.out_2);
   else
     $display(" *** T=%0t [Scoreboard] PASS! select=%0d -- data_1=0x%0h -- out_1=0x%0h -- out_2=0x%0h ",$time,item.select,item.data_1,item.out_1, item.out_2);
 end
endtask
endclass

/*    ### ENV CLASS ### */
class env;
driver            d0;
monitor           m0;
generator         g0;
scoreboard        s0;

mailbox           drv_mbx;
mailbox           scb_mbx;
event             drv_done;
virtual demux_if  vif;


//Instantiate all testbench components
function new();
 $display("  T=%0t [Env] starting ... ",$time);
 d0 = new;
 m0 = new;
 g0 = new;
 s0 = new;
 scb_mbx = new();
 drv_mbx = new();
 
 d0.drv_mbx = drv_mbx;
 g0.drv_mbx = drv_mbx;
 
 m0.scb_mbx = scb_mbx;
 s0.scb_mbx = scb_mbx;
 
 d0.drv_done = drv_done;
 g0.drv_done = drv_done;
endfunction

virtual task run();
 d0.vif = vif;
 m0.vif = vif;
 
 fork
   s0.run();
   d0.run();
   m0.run();
   g0.run();
  join_any
endtask
endclass

/*    ### TEST CLASS ### */
class test;
env e0;

function new();
 e0 = new;
endfunction

 task run();
  $display("  T=%0t [Test] starting ... ",$time);
   e0.run();
 endtask
endclass

/*    ### INTERFACE ### */
interface demux_if(input bit clk);
 logic reset;
 logic [(DATA_PACKET_SIZE-1):0] data_1;
 logic select;
 logic [(DATA_PACKET_SIZE-1):0] out_1;
 logic [(DATA_PACKET_SIZE-1):0] out_2;
endinterface

/*    ### TESTBENCH ### */
module DEMUX2NewTB;
//localparam DATA_PACKET_SIZE = 4;
localparam period = 2;
logic clk;

always begin
    #(period/2) clk <= ~clk;
  end
  
  
  
  demux_if if_dut(clk);
  //DUT INSTANTIATION 
  DEMUX2
 #(
.DATA_PACKET_SIZE (DATA_PACKET_SIZE)
)
  dut
   (
    .clk(clk),
	.reset(if_dut.reset),
    .data_1(if_dut.data_1),
	.select(if_dut.select),
	 
	.out_1(if_dut.out_1),
	.out_2(if_dut.out_2)
   );  
  
  test t0;
  
  initial begin
    clk <= 0;
    if_dut.reset <= 1;
  
    //de-asserting the reset
    #(period*5) if_dut.reset <= 0;
    t0 = new;
    t0.e0.vif = if_dut;
    t0.run();
    
    #(period*50) $stop;
  end
  
  initial begin
    $dumpfile("DEMUX2.vcd");
    $dumpvars; 
  end

endmodule
