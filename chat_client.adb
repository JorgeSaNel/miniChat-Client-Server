-- Jorge Santos Neila
-- Doble Grado en Sist. Telecomunicación + ADE

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Text_IO;
with Ada.Command_Line;

with Lower_Layer_UDP;
with Chat_Messages;

procedure Chat_Client is
	package LLU renames Lower_Layer_UDP;
	package ASU renames Ada.Strings.Unbounded;
	package CM renames Chat_Messages;
	use type CM.Message_Type;

	procedure Arguments_Input (Dir_Ip: out ASU.Unbounded_String; Port: out Natural;
							   Nick_Name: out ASU.Unbounded_String) is
		package ACL renames Ada.Command_Line;
	begin
		Dir_IP := ASU.To_Unbounded_String(ACL.Argument(1));
		Dir_IP := ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Dir_IP)));
		Port := Integer'Value(ACL.Argument(2));
		Nick_Name := ASU.To_Unbounded_String(ACL.Argument(3));
	end Arguments_Input;

	procedure Read_String (Strings : out ASU.Unbounded_String) is
		package ASU_IO renames Ada.Strings.Unbounded.Text_IO;
	begin
		Put("Mensaje: ");
		Strings := ASU_IO.Get_Line;
	end Read_String;

	Server_EP: LLU.End_Point_Type;
	Client_EP: LLU.End_Point_Type;
	Buffer: aliased LLU.Buffer_Type(1024);

	Dir_IP, Nick_Name: ASU.Unbounded_String;
	Port: Natural;
	Message: ASU.Unbounded_String;
	Mess: CM.Message_Type;
begin
	Arguments_Input(Dir_Ip, Port, Nick_Name);
	Server_EP := LLU.Build(ASU.To_String(Dir_IP), Port); --Build End_Point in which the server is bound
	LLU.Bind_Any(Client_EP); --Build a free End_Point

	CM.Message_Type'Output(Buffer'Access, CM.Init); -- Introduce Message Type
	LLU.End_Point_Type'Output(Buffer'Access, Client_EP); -- Introduce End_Point
	ASU.Unbounded_String'Output(Buffer'Access, Nick_Name); -- Introduce Nick_Name		
	LLU.Send(Server_EP, Buffer'Access); --Send it to the Server 

	if ASU.To_String(Nick_Name) /= "lector" then --Writer Mode
			Mess := CM.Writer;
		loop
			Read_String(Message);
			exit when ASU.To_String(Message) = ".salir";
			
			LLU.Reset(Buffer);
			CM.Message_Type'Output(Buffer'Access, Mess); 
			LLU.End_Point_Type'Output(Buffer'Access, Client_EP); 
			ASU.Unbounded_String'Output(Buffer'Access, Message);
			LLU.Send(Server_EP, Buffer'Access);
		end loop;
	else --Lector Mode
		loop
			LLU.Receive(Client_EP, Buffer'Access);
			
			Mess := CM.Message_Type'Input(Buffer'Access);
			Nick_Name := ASU.Unbounded_String'Input(Buffer'Access);
			Message := ASU.Unbounded_String'Input(Buffer'Access);
			Put_Line(ASU.To_String(Nick_Name) & ": " & ASU.To_String(Message));
		end loop;
	end if;
	LLU.Finalize;
end;
