`timescale 10ns / 1ns

module reg_test
();

	// TODO: implement your testbench
	 //long and short data wide
    parameter ShortDataWide= 4;
    parameter LongDataWide = 32;
    parameter ShortAddrWide= 2;
    parameter LongAddrWide = 5;
    parameter ShortMaxData = 5'b1_0000;
    parameter LongMaxData  = 33'b1_0000_0000_0000_0000_0000_0000_0000_0000;
    //use
    parameter DataWide = LongDataWide;
    parameter AddrWide = LongAddrWide;    
    parameter MaxData  = ShortMaxData;
    parameter MaxAddr  = DataWide;
    //time
    parameter c=2;// 1c is a whole clk 
 //   parameter OneRunTime=MaxData*MaxData*c; //
 //   parameter stoptime=5*OneOrderTime; //five ALU control order
    //file
    integer filew;
    //counting
    integer i;
    //reg input
    reg clk;
    reg rst;
    reg[AddrWide-1:0] waddr,raddr1,raddr2;
    reg wen;
    reg[DataWide-1:0] wdata;
    //reg output
    wire [DataWide-1:0] rdata1,rdata2;
    
    
reg_file reg_t(clk,rst,waddr,raddr1,raddr2,wen,wdata,rdata1,rdata2);

    always #(0.5*c) clk=~clk;
    
    initial
        fork
        //initial all number
        clk=0;
        rst=1;
        #(0.8*c) rst=0;//clear reg
        wen=1;
        wdata=0;
        waddr=0;
        raddr1=0;
        raddr2=0;
        filew=$fopen("file01.txt");
        join
    
    initial
      begin
        //all test
            //change at posedge clk  
        #(1.5*c)   ;

 ////////////////////////////////////////////////////////////////////////////////////////////////
     begin  //2 test1: wen=1,write and read all data in all space
           repeat(MaxData)
               begin //3
                    
                //write one data into all space
                    repeat(MaxAddr)                    
                    begin//4
                        @(negedge clk)
                        #(0.2*c)
                         waddr=waddr+1;
                    end//4repeat waddr

               //read_1 read all data
                    repeat(MaxAddr)
                        //write one data into all space
                        begin//5
                           @(posedge clk)
                           #(0.2*c)
                           raddr1=raddr1+1;
                           //display
                           @(negedge clk)
                           if( (raddr1!==0)&&(rdata1==wdata)||(raddr1===0)&&(rdata1===0) )
                           begin//6
                           $display($time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, rignt\n",wen,rst,raddr1,rdata1,wdata);
                           $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, rignt\n",wen,rst,raddr1,rdata1,wdata);  
                           end//6if
                           else
                           begin//7
                           $display($time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, error***********\n",wen,rst,raddr1,rdata1,wdata);
                           $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, error***********\n",wen,rst,raddr1,rdata1,wdata);                             
                           end//7else                                          
                        end//5repeat raddr1                  
                       
               //read_2 read all data
                    repeat(MaxAddr)
                        //write one data into all space
                        begin//8
                           @(posedge clk)
                           #(0.2*c)
                           raddr2=raddr2+1;                           
                           //display
                           @(negedge clk)
                           if(  (raddr2!==0)&&(rdata2==wdata)||(raddr2===0)&&(rdata2===0)  )
                           begin//9
                           $display($time,"  wen=%b, rst=%b, raddr2=%b, rdata2=%b, wdata=%b, rignt\n",wen,rst,raddr2,rdata2,wdata);
                           $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr2=%b, rdata2=%b, wdata=%b, rignt\n",wen,rst,raddr2,rdata2,wdata);  
                           end//9 if
                           else
                           begin//10
                           $display($time,"  wen=%b, rst=%b, raddr2=%b, rdata2=%b, wdata=%b, error***********\n",wen,rst,raddr2,rdata2,wdata);
                           $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr2=%b, rdata2=%b, wdata=%b, error***********\n",wen,rst,raddr2,rdata2,wdata);                             
                           end//10 else                           
                        end//8 repeat raddr2                
   
                    //new data
                   #(2*c) wdata=wdata+1;
               end//3 end repeat write and read 

          end//2 test1  
 
////////////////////////////////////////////////////////////////////////////////////////////////            

          begin  //11 test2:wen=0
            wen=0;
            wdata=MaxData/2;               
            
            //write one data into all space
                repeat(MaxAddr)                    
                begin//12
                    #c waddr=waddr+1;                    
                end//12 repeat waddr
            
            //read_1 read all data
                repeat(MaxAddr)
                    //write one data into all space
                    begin//13
                        @(posedge clk)raddr1=raddr1+1;
                        //display
                        @(negedge clk)
                        if( rdata1 !== wdata )
                        begin//14
                        $display($time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, rignt\n",wen,rst,raddr1,rdata1,wdata);
                        $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, rignt\n",wen,rst,raddr1,rdata1,wdata);  
                        end//14 if
                        else
                        begin//15 
                        $display($time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, error***********\n",wen,rst,raddr1,rdata1,wdata);
                        $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, error***********\n",wen,rst,raddr1,rdata1,wdata);                             
                        end//15 else                                                                  
                    end//13 repeat raddr1                  
            
            //read_2 read all data
                repeat(MaxAddr)
                    //write one data into all space
                    begin//16
                        @(posedge clk)raddr2=raddr2+1;
                        //display
                        @(negedge clk)
                        if(  rdata2 !== wdata  )
                        begin//17
                        $display($time,"  wen=%b, rst=%b, raddr2=%b, rdata2=%b, wdata=%b, rignt\n",wen,rst,raddr2,rdata2,wdata);
                        $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr2=%b, rdata2=%b, wdata=%b, rignt\n",wen,rst,raddr2,rdata2,wdata);  
                        end//17 if
                        else
                        begin//18
                        $display($time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, error***********\n",wen,rst,raddr1,rdata1,wdata);
                        $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, error***********\n",wen,rst,raddr1,rdata1,wdata);                             
                        end//18 else
                    end//16 repeat raddr2
         end//11 test2            
     

////////////////////////////////////////////////////////////////////////////////////////////////
     begin  //19 test3:rst=1
            wen=1;
            wdata=MaxData-1;
            rst=1;
             @(posedge clk);
             @(negedge clk)  
             begin //20 
            //read_1 read all data
                repeat(MaxAddr)
                    //write one data into all space
                    begin//21
                        raddr1=raddr1+1;
                        //display
                        if( rdata1 === 0 )
                        begin//22
                        $display($time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, rignt\n",wen,rst,raddr1,rdata1,wdata);
                        $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, rignt\n",wen,rst,raddr1,rdata1,wdata);  
                        end//22 if
                        else
                        begin//23
                        $display($time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, error***********\n",wen,rst,raddr1,rdata1,wdata);
                        $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, error***********\n",wen,rst,raddr1,rdata1,wdata);                             
                        end//23 else                                                                                          
                    end//21 repeat raddr1                  
            
            //read_2 read all data
                repeat(MaxAddr)
                    //write one data into all space
                    begin//24
                        raddr2=raddr2+1;
                        //display
                        if(  rdata2 === 0  )
                        begin//25
                        $display($time,"  wen=%b, rst=%b, raddr2=%b, rdata2=%b, wdata=%b, rignt\n",wen,rst,raddr2,rdata2,wdata);
                        $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr2=%b, rdata2=%b, wdata=%b, rignt\n",wen,rst,raddr2,rdata2,wdata);  
                        end//25 if
                        else
                        begin//26
                        $display($time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, error***********\n",wen,rst,raddr1,rdata1,wdata);
                        $fdisplay(filew,$time,"  wen=%b, rst=%b, raddr1=%b, rdata1=%b, wdata=%b, error***********\n",wen,rst,raddr1,rdata1,wdata);                             
                        end//26 else                        
                    end//24 repeat raddr2
             end//20 negedge clk     
         end//19 test3
//////////////////////////////////////////////////////////////////////////////////////
    begin   //test4: read and write a same register
    wen=1;
    rst=0;
    waddr=0;
    raddr1=0;
    raddr2=0;
    wdata=MaxData/2+1;
    @(negedge clk)
        #(0.2*c)
        waddr=1;
    @(posedge clk)
        #(0.2*c)
        raddr1=1;
        #(0.1*c)
        raddr2=1;
    @(posedge clk);
    end     
     $stop;
      end                                              

////////////////////////////////////////////////////////////////////////////////////////////////            
            //stop
 /*           $stop
       end//1 end all test
*/
//        end      
    
    //check output
/*     always@(posedge clk)
     begin
        if( (
                ( wen===0 ) && (rdata1!==wdata) && (rdata2!==wdata)
            )//wen==0
            ||
            (
                ( wen===1 ) && (rst!==1) 
                && ( (raddr1!==0)&&(rdata1==wdata)||(raddr1===0)&&(rdata1===0) ) 
                && ( (raddr2!==0)&&(rdata2==wdata)||(raddr2===0)&&(rdata2===0) ) 
            )//wen==1,rst==0
            ||
            (
               ( wen===1 ) && (rst===1) && (rdata1===0) && (rdata2===0)                                
            ) //wen===1,rst===1           
           )//if 
        begin
        //todo
        end//if
     end//always
 */   
endmodule
