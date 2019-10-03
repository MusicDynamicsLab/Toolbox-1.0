%% zdotNorm
%  n = zdotNorm(M, nx, kx)
%
%  Updates a single network M.n{nx} for kx step of Runge-Kutta integration
%  Includes buffer normalization for connections
%
%  Input arguments:
%  M        Model
%  nx       Network id
%  kx       Runge-Kutta step index
%
%  Output:
%  n        Updated network object
%

%%
function n = zdotNorm(M, nx, kx)
%% Initialize variables and stimulus

n   = M.n{nx};
z   = n.z;
a   = n.a;
b1  = n.b1;
b2  = n.b2;
e   = n.e;
h = M.dt;

%% Add input

x = 0;

for cx = 1:length(n.con)
    con = n.con{cx};
    if con.nSourceClass == 1
        y = M.s{con.source}.z;
    else
        y = M.n{con.source}.z;
    end
    
    switch con.nType    % cases ordered by frequency of use
        
        case 1  % 1freq
            x = x + con.w.*(con.C*y);
            
        case 6  % all2freq
            CP = con.C*P(e, y); % raw c*P
            if con.no11
                subtract = sum(con.C.*( A(e^2, z*y').*repmat(y.', con.targetN, 1) ), 2);
            else
                subtract = 0;
            end
            
        case 7  % allfreq
            CP = con.C*P_new(e, y); % raw C*P
            if con.no11
                subtract = sum(con.C.*( A(e^2, z*y').*repmat(y.'.*A(e^2, abs(y.').^2), con.targetN, 1) ), 2);
            else
                subtract = 0;
            end
            
        case 2  % 2freq
            NUM = con.NUM;
            DEN = con.DEN;
            Y = repmat(sqrt(e)*y.', con.targetN, 1).^ NUM;
            Z = repmat(sqrt(e)*conj(z) , 1, con.sourceN).^(DEN-1);
            x = x + con.w .* sum(con.C.*Y.*Z,2)/sqrt(e);
            
        case 5  % active
            CP = con.C*y; % raw C*P
            if con.no11
                subtract = y;
            else
                subtract = 0;
            end
            
        otherwise % 3freq and 3freqall
            Y1 = sqrt(e)*y(con.IDX1); Y1(con.CON1) = conj(Y1(con.CON1));
            Y2 = sqrt(e)*y(con.IDX2); Y2(con.CON2) = conj(Y2(con.CON2));
            Z  = sqrt(e)*conj(z(con.IDXZ));
            NUM1 = con.NUM1;
            NUM2 = con.NUM2;
            DEN = con.DEN;
            x_int = con.C.*(Y1.^NUM1).*(Y2.^NUM2).*(Z.^(DEN-1))/sqrt(e);
            x = x + con.w .* sum(x_int,2);
            
    end
    
    % Computation and normalization of input for all2freq, allfreq, active
    if ismember(con.nType, [5 6 7])
        if con.norm
            hx = con.hx; % current buffer head position
            buffer = con.buffer;
            Lbuf = con.Lbuf; % buffer length
            
            buffer(hx) = max(abs(CP)); % save to buffer
            maxBuf = max(buffer); % max in buffer
            thrNorm = con.thrNorm; % normalization threshold
            if maxBuf > thrNorm
                multNorm = thrNorm/maxBuf; % multiplier for normalization
            else
                multNorm = 1;
            end
            
            n.con{cx}.buffer = buffer;
            n.con{cx}.hx = mod(hx, Lbuf) + 1; % advance head
        else
            multNorm = 1;
        end
        
        x = x + multNorm * con.w .* (CP.*A(e, z) - subtract);
    end
    
end

%% The differential equation
% $\dot{z} = z \left( \alpha + \textrm{i}\omega + (\beta_1 + \textrm{i}\delta_1) |z|^2 + \frac{\epsilon (\beta_2 + \textrm{i}\delta_2) |z|^4}{1-\epsilon |z|^2} \right) + x$
dzdt = z.*(a + b1.*abs(z).^2 + e*b2.*(abs(z).^4)./(1-e*abs(z).^2)) + x;
n.k{kx} = h*dzdt;

%%  Nonlinear Function Definitions
function y = P(epsilon, x)
y = ( x ./ (1 - sqrt(epsilon)*x) );

function y = P_new(epsilon, x)
y = ( x ./ (1 - sqrt(epsilon)*x) ) .* ( 1 ./ (1 - sqrt(epsilon)*conj(x) ));
%y = y - Pc(epsilon, x);

function y = A(epsilon, z)
y = ( 1 ./ (1 - sqrt(epsilon)*conj(z) ));

function y = Pc(epsilon, x)
y = ( sqrt(epsilon)*x.*conj(x) ./ (1 - epsilon*x.*conj(x)) );

function y = Ac(epsilon, x, z)
y = ( sqrt(epsilon)*x.*conj(z) ./ (1 - epsilon*x.*conj(z)) );

function y = H(epsilon, r)
y = (epsilon * r.^4 ./ (1- epsilon * r.^2) );
