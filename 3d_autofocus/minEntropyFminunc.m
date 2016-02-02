% The following is a MATLAB implementation of the standard gradient descent
% minimization of the image entropy cost function. The below algorithm
% implements the technique described analytically in 'tech_report.pdf'.
%
% B is a 4D array of b_k values
% L is the number of iterations
function [ out, minEntropy ] = minEntropyFminunc( B, L )
  MAX_ITER = 10;
  X = size(B,1); Y = size(B,2); Z = size(B,3); K = size(B,4);
  l = 2;
  minIdx = 1;
  minEntropy = 100;

  % Holds array of potentially minimizing phase offsets - 100 is an arbitrary
  % maximum number of iterations
  %
  % Guess zero initially
  phi_offsets = zeros(MAX_ITER, K);

  % Step size parameter for gradient descent
  s = 10;
  
  % As iterating over a 4D array reduces spatial locality, convert `B` once
  % into a 1D array and then convert back after minimization of phi is
  % complete. 
  % TODO: (joshpfosi) Could potentially use `cat` here
  B_tmp = [];
  for x = 1:X
      for y = 1:Y
          for z = 1:Z
                B_tmp = horzcat(B_tmp, reshape(B(x,y,z,:), 1, K));
          end
      end
  end
  
  B = B_tmp;
  clear('B_tmp');
  while (1) % phi_offsets(1) = 0
    phi_offsets(l, :) = phi_offsets(l - 1, :) - s * grad_h(complex(phi_offsets(l - 1, :)), B);
    focusedImage = z_vec(complex(phi_offsets(l, :)), B);
    tempEntropy = H_matlab(focusedImage);
    
    fprintf('tempEntropy = %d, minEntropy = %d\n', tempEntropy, minEntropy);
    if (tempEntropy < minEntropy && minEntropy - tempEntropy > 0.5) % break if decreases in entropy are small
        minIdx = l;
        minEntropy = tempEntropy;
    else
        break;
    end
    s = s / 1;
    l = l + 1;
  end
  
  % `focusedImage` now contains the 1D representation of the entropy-minimized
  % B, constructed using phase offsets `phi_offets(minIdx)`. We must reshape it
  % back into a 3D array.
  % TODO: (joshpfosi) Use `reshape` instead of ugly `for`s.
  out = zeros(X,Y,Z);
  for x = 1:X
      for y = 1:Y
          for z = 1:Z
              % We must index into the 1D array as if it were 3D so the index
              % is complicated.
              idx = (x - 1) * Y * Z + (y - 1) * Z + (z - 1) + 1;
              out(x,y,z) = focusedImage(idx);
          end
      end
  end
end

% Returns the entropy of the complex image `Z`
function [ entropy ] = H_matlab( Z )
  Z_mag = Z .* conj(Z);         
  Ez = findEz(Z_mag);

  Z_intensity = Z_mag / Ez;
  % TODO: (joshpfosi) Why is this negated?
  entropy = - sum(Z_intensity .* log(Z_intensity));
end

% Returns the total image energy of the complex image Z given the magnitude of
% the pixels in Z
function [ Ez ] = findEz( Z_mag )
  Ez = sum(Z_mag);
end
