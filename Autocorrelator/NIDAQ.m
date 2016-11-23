% CLIENT connect to a server and read a message
%
% Usage - message = client(host, port, number_of_retries)
function [answer input_socket] = NIDAQ(host, port, msg, input_socket)

    import java.net.Socket
    import java.io.*
     
    if nargin < 4
        input_socket = [];
    end
    [command remains] = strtok(msg);
    [chan remains2] = strtok(remains);
    [sp remains3] = strtok(remains2);
    numcha = length(char(sp));
    if strcmp(command,'ANALOGIN') == 1
        waiting = 0.25*numcha;
    else
        waiting = 0.5;
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
            if (strcmp('QUIT',msg)) ~= 1
                for i=1:size(msg,2) 
                    message = sprintf('%s\r\n',msg{i});

                    if strcmp(command,'READ') ~= 1
                        output_stream   = input_socket.getOutputStream;
                        d_output_stream = DataOutputStream(output_stream);

                        % output the data over the DataOutputStream
                        % Convert to stream of bytes
                        d_output_stream.writeBytes(char(message));
                        d_output_stream.flush;
                    end

                    %get a buffered data input stream from the socket

                    if strcmp(command,'TRIGGERCCD') ~= 1
                        input_stream   = input_socket.getInputStream;
                        in_read = InputStreamReader(input_stream);
                        d = BufferedReader(in_read);

                        %d_input_stream = DataInputStream(input_stream);

                        % read data from the socket - wait a short time first
                        pause(waiting);
                        bytes_available = input_stream.available;

                        if(bytes_available>0)
                            for j = 1:bytes_available
                             responseni(j) = d.read;
                            end
                        end
                        % cleanup
                        if(bytes_available>0)
                            answer = [answer, {char(responseni(1:bytes_available))}];
                        end
                    end
                end
            else
                input_socket.close;
            end

            break;
        catch
            lasterr
            
            % pause before retrying
            pause(0.1);
        end
    end
    %clc;
end