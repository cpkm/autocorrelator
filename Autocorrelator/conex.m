% CLIENT connect to a server and read a message
%
% Usage - message = client(host, port, number_of_retries)
function [answer input_socket] = conex(host, port, msg, input_socket)

    import java.net.Socket
    import java.io.*
     
    if nargin < 4
        input_socket = [];
    end
        number_of_retries = 1; % set to -1 for infinite
        
    answer       = {};
    retry        = 0;
    message      = [];

    while true

        retry = retry + 1;
        if ((number_of_retries > 0) && (retry > number_of_retries))
            answer = {'Server not running or network problem'};
            break;
        end
        
        try
            % throws if unable to connect
            if isempty(input_socket) == 1
                input_socket = Socket(host, port);
            end

            for i=1:size(msg,2) 
                message = sprintf('%s\r\n',msg{i});

                output_stream   = input_socket.getOutputStream;
                d_output_stream = DataOutputStream(output_stream);

                % output the data over the DataOutputStream
                % Convert to stream of bytes
                d_output_stream.writeBytes(char(message));
                d_output_stream.flush;

                %get a buffered data input stream from the socket
                input_stream   = input_socket.getInputStream;
                in_read = InputStreamReader(input_stream);
                d = BufferedReader(in_read);

                %d_input_stream = DataInputStream(input_stream);

                % read data from the socket - wait a short time first
                pause(0.5);
                bytes_available = input_stream.available;

                if(bytes_available>0)
                    for i = 1:bytes_available
                     response(i) = d.read;
                    end
                end
                % cleanup
                if exist('response') ~= 0
                    answer = [answer, {char(response(1:bytes_available))}];
                end
            end
            if strcmp(msg(1),'QUIT') == 1
                input_socket.close;
            end
            break;
        catch
            lasterr
            
            % pause before retrying
            pause(0.1);
        end
    end
end