-- Jorge Santos Neila
-- Doble Grado en Sist. Telecomunicación + ADE

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Command_Line;

with Lower_Layer_UDP;
with Chat_Messages;

procedure Chat_Server is
	package ASU renames Ada.Strings.Unbounded;
	package LLU renames Lower_Layer_UDP;
	package CM renames Chat_Messages;
	use type CM.Message_Type;
	use type LLU.End_Point_Type;
	
	procedure Create_Server(Server_EP: in out LLU.End_Point_Type) is
		Host_Name: ASU.Unbounded_String;
		Port: Natural;
	begin
		Host_Name := ASU.To_Unbounded_String(LLU.Get_Host_Name);
		Host_Name := ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Host_Name)));
		Port := Integer'Value(Ada.Command_Line.Argument(1));

		Server_EP := LLU.Build(ASU.To_String(Host_Name), Port);
		LLU.Bind(Server_EP);
	end Create_Server;

	procedure Message_Init(Client: in out CM.Mult_Client; Num: in out Integer; P_Buffer: access LLU.Buffer_Type) is
		Nick_Name: ASU.Unbounded_String;
	begin
		Client(Num).Client_EP := LLU.End_Point_Type'Input(P_Buffer);
		Nick_Name := ASU.Unbounded_String'Input(P_Buffer);
		Client(Num).Nick_Name := Nick_Name;
		if ASU.To_String(Nick_Name) /= "lector" then
			Put_Line("Recibido mensaje inicial de " & ASU.To_String(Nick_Name));
		else
			Client(Num).Lector := True;
		end if;
		Num := Num + 1;
	end Message_Init;
	
	procedure Analyze_Send (P_Buffer: access LLU.Buffer_Type; Num_Client: Integer; Client: CM.Mult_Client) is
		Extrac_EP: LLU.End_Point_Type;
		Message, Nick_Name: ASU.Unbounded_String;
	begin
		Extrac_EP := LLU.End_Point_Type'Input(P_Buffer);
		Message := ASU.Unbounded_String'Input(P_Buffer);
		for I in 0..Num_Client loop
			if Client(I).Client_EP = Extrac_EP then
				Nick_Name := Client(I).Nick_Name;
				Put_Line("Recibido mensaje de " & ASU.To_String(Nick_Name) & ": " & ASU.To_String(Message));
				exit;
			end if;
		end loop;
		
		--Send Message to Client_Lector
		for I in 0..Num_Client loop
			if Client(I).Lector then
				LLU.Reset(P_Buffer.all);

				CM.Message_Type'Output(P_Buffer, CM.Server);
				ASU.Unbounded_String'Output(P_Buffer, Nick_Name);
				ASU.Unbounded_String'Output(P_Buffer, Message);
				LLU.Send(Client(I).Client_EP, P_Buffer);
			end if;
		end loop;
	end Analyze_Send;
	
	Server_EP: LLU.End_Point_Type;
	N_Client: CM.Mult_Client;
	Num: Integer := 0;
	Buffer: aliased LLU.Buffer_Type(1024);

	Mess: CM.Message_Type;
begin
	Create_Server(Server_EP);

	loop
		LLU.Reset(Buffer);
		LLU.Receive(Server_EP, Buffer'Access);
		
		Mess := CM.Message_Type'Input(Buffer'Access);
		if Mess = CM.Init then
			Message_Init(N_Client, Num, Buffer'Access);
		elsif Mess = CM.Writer then
			Analyze_Send(Buffer'Access, Num, N_Client);
		end if;
	end loop;

end;
