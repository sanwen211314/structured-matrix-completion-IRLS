%% Produce the plots for the ratio of the average error and relative errors for sIRLS and Structured sIRLS
close all;  clear all;
format compact;  format long e;
tic

% Range of the sampling rate of non-zero entries
rate1_vector = 0.1:0.05:1;
r1 = size(rate1_vector,2);

% Range of the sampling rate of zero entries
rate2_vector = 0.1:0.05:1;
r2 = size(rate2_vector,2);

% Number of matrices considered
m = 100; n = 100;
numMat = 10; % number of matrices
r = 10; % rank of the matrices
errorMatA = zeros(r1,r2); % errors of of sIRLS-1
errorMatB = zeros(r1,r2); % errors of Structured sIRLS-1,1

% sIRLS parameters
type = 2;
q = 1; p = 1;

% Noise level
noise_exp = 0; % set equal to 0 to run exact recovery experiments
% set equal to 1 to run experiments with noise
eps_noise = 10^(-3); % set the noise parameter (or ratio)

%% Matrix Completion using both methods
for k = 1 : numMat
    
    % Construct a random matrix
    YL = sprand(m,r,0.3);
    YR = sprand(r,n,0.5);
    Y = YL*YR;
    Y = full(Y)/norm(Y, 'fro');
    Y_original = Y;
    
    for i = 1 : r1
        rate1 = rate1_vector(i);
        
        [f,h,s] = find(Y);
        szi1 = size(f,1);
        k1 = round(rate1*szi1);
        
        % Subsmapling (100*rate1) percent of non-zero entries
        [y_f,idx] = datasample(f,k1,'Replace',false); % randomly subsample k1 non-zero entries
        y_h = h(idx);
        
        for j = 1 : r2
            rate2 = rate2_vector(j);
            [u,v] = find(Y == 0);
            szi2 = size(u,1);
            k2 = round(rate2*szi2);
            
            % Subsmapling (100*rate2) percent of zero entries
            [y_u,idu] = datasample(u,k2,'Replace',false); % randomly subsample k2 zero entries
            y_v = v(idu);
            
            % Storing the entries of the "observed" entries
            Obs_i = [y_f ; y_u];
            Obs_j = [y_h ; y_v];
            
            % Constructing the Mask
            Mask = zeros(m,n);
            Mask(sub2ind(size(Y), Obs_i, Obs_j)) = 1;
            [mis_i, mis_j] = find(Mask == 0);
            
            % Perturbing the Obeserved Entry
            if noise_exp == 1
                N_noise = randn(size(Obs_i));
                noise_ratio =  norm(Y(sub2ind(size(Y), Obs_i, Obs_j)),2)/norm(N_noise,2);
                Z_noise = eps_noise * noise_ratio* N_noise;
                % noise_norm = norm(Z_noise,2);
                Y(sub2ind(size(Y), Obs_i, Obs_j)) = Y(sub2ind(size(Y), Obs_i, Obs_j)) + Z_noise;
            end
            
            % Construct M for sIRLS
            M = [Obs_i, Obs_j, Y(sub2ind(size(Y), Obs_i, Obs_j))];
            
            % Find the error using sIRLS-1
            errorMatA(i,j) = errorMatA(i,j) + run_sIRLS_p(Y_original,M,m,n,r,2);
            
            % Find the error using Structured sIRLS-1,1
            errorMatB(i,j) = errorMatB(i,j) + run_structured_sIRLS(q,p,Y_original,M,m,n,r);
            
        end
    end
end
% ratio of the relative error between the two methods
relError =  errorMatB./errorMatA;
toc

%% Plot the matrix of ratio of the average errors
figure;
imagesc(rate2_vector, rate1_vector, flipud(relError))
%caxis([0 mmax])
set(gca, 'XTick', 0.1:0.1:1, 'XTickLabel', 0.1:0.1:1,'FontSize',14);
set(gca, 'YTick', 0.1:0.1:1, 'YTickLabel', 1:-0.1:0.1, 'FontSize',14);
xlabel('Sampling rate of zero entries', 'FontSize',16); ylabel('Sampling rate of non-zero entries', 'FontSize',16);
%title('Average ratio error')
colorbar

%% Plot relative errors for each method
errorMatA = errorMatA./numMat;
errorMatB = errorMatB./numMat;

eA = max(errorMatA(:));
eB = max(errorMatB(:));
emax = max(eA,eB);

figure;
imagesc(rate2_vector, rate1_vector, flipud(errorMatA))
caxis([0 emax])
set(gca, 'XTick', 0.1:0.1:1, 'XTickLabel', 0.1:0.1:1,'FontSize',14);
set(gca, 'YTick', 0.1:0.1:1, 'YTickLabel', 1:-0.1:0.1,'FontSize',14);
xlabel('Sampling rate of zero entries', 'FontSize',16); ylabel('Sampling rate of non-zero entries', 'FontSize',16);
%title('Relative average error of sIRLS')
colorbar

figure;
imagesc(rate2_vector, rate1_vector, flipud(errorMatB))
caxis([0 emax])
set(gca, 'XTick', 0.1:0.1:1, 'XTickLabel', 0.1:0.1:1,'FontSize',14);
set(gca, 'YTick', 0.1:0.1:1, 'YTickLabel', 1:-0.1:0.1,'FontSize',14);
xlabel('Sampling rate of zero entries', 'FontSize',16); ylabel('Sampling rate of non-zero entries', 'FontSize',16);
%title('Relative average error of Structured sIRLS')
colorbar

% Plot binary results
relError_scaled = relError;
for i = 1 : r1
    for j = 1 : r2
        if(relError(i,j)>= 1)
            relError_scaled(i,j) = 1;
        else 
            relError_scaled(i,j) = 0;
        end
    end
end

figure;
imagesc(rate2_vector, rate1_vector, flipud(relError_scaled))
colormap(gray); 
set(gca, 'XTick', 0.1:0.1:1, 'XTickLabel', 0.1:0.1:1,'FontSize',14);
set(gca, 'YTick', 0.1:0.1:1, 'YTickLabel', 1:-0.1:0.1, 'FontSize',14);
xlabel('Sampling rate of zero entries', 'FontSize',18); ylabel('Sampling rate of non-zero entries', 'FontSize',18);


