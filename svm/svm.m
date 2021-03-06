1;

%source('svm/svm_learningCurves.m');
source('svm/graphics.m');
source('extra/gaussianKernel.m');
warning('off');

% Main function of the logistic regression analysis
function [model] = svm(posExamples,negExamples)
	% PARAMETERS
	normalize = false; % Normalize the data or not
	percentage_training = 0.4; % Training examples / Total examples
	adjusting = false; % Activates adjustment process
	C =  1; % Default C parameter
	sigma = 1; % Default sigma parameter
	
	% ADJUSTMENT PARAMETERS (ONLY APPLIES IF adjusting = true)
	percentage_adjustment= 0.05; % Adjustment examples / Total examples
	values = [0.5,1,5,10]; % Possible combinations of C and sigma
	
	%------------------------------------------------------------------------------
	% Distribution of the examples (Positive and negative examples are equally
	% distributed)
	
	% Number of features
	numFeatures = columns(posExamples);
	
	% Number of training examples
	n_tra_pos = fix(percentage_training * rows(posExamples));
	n_tra_neg =	fix(percentage_training * rows(negExamples));
	
	% Selection of training examples
	traExamples = [posExamples(1:n_tra_pos,:);negExamples(1:n_tra_neg,:)];
	
	% Permute the order of the training examples
	traExamples = traExamples(randperm(size(traExamples,1)),:);
	
	X_tra = traExamples(:,1:numFeatures-1);
	Y_tra = traExamples(:,numFeatures);
	
	if(adjusting)
		% Number of adjustment examples
		n_adj_pos = fix(percentage_adjustment * rows(posExamples));
		n_adj_neg =	fix(percentage_adjustment * rows(negExamples));

		% Number of validation examples
		n_val_pos = rows(posExamples) - (n_tra_pos + n_adj_pos);
		n_val_neg =	rows(negExamples) - (n_tra_neg + n_adj_neg);

		% Selection of adjustment examples
		adjExamples = [posExamples(n_tra_pos+1:n_tra_pos+n_adj_pos,:); ...
					   negExamples(n_tra_neg+1:n_tra_neg+n_adj_neg,:)];

		% Permute the order of the adjustment examples
		adjExamples = adjExamples(randperm(size(adjExamples,1)),:);
	
		X_adj = adjExamples(:,1:numFeatures-1);
	
		% Selection of validation examples
		valExamples = [posExamples(n_tra_pos+n_adj_pos+1:rows(posExamples),:);
		               negExamples(n_tra_neg+n_adj_neg+1:rows(negExamples),:)];
	
		% Permute the order of the validation examples
		valExamples = valExamples(randperm(size(valExamples,1)),:);
	
		if(normalize)
			X_adj = featureNormalize (X_adj);
		end
		Y_adj = adjExamples(:,numFeatures);
	
	else
		% Number of validation examples
		n_val_pos = rows(posExamples) - n_tra_pos;
		n_val_neg = rows(negExamples) - n_tra_neg;
		valExamples = [posExamples(n_tra_pos+1:rows(posExamples),:);
		               negExamples(n_tra_neg+1:rows(negExamples),:)];
	
		% Permute the order of the validation examples
		valExamples = valExamples(randperm(size(valExamples,1)),:);
	end
	
	X_val = valExamples(:,1:numFeatures-1);
	Y_val = valExamples(:,numFeatures);
	
	if (normalize)
			X_tra = featureNormalize (X_tra);
			X_val = featureNormalize (X_val);
	end
	
	if (adjusting)
		% Adjustment process(Search of optimal C and sigma)
		fprintf('\nAdjusting ...');
		fflush(stdout);
		dots = 12;
		for i=1:length(values)
			for j=1:length(values)
				model = svmTrain(X_adj, Y_adj, values(i),false, ...
				                 @(x1, x2)gaussianKernel(x1, x2,values(j)));
				% We select the best F-Score for each pair of values
				[n,n,FScoreMatrix(i, j)] = svm_precisionRecall(X_adj, Y_adj,model);
				fprintf('.');
				dots = dots + 1;
				if dots > 78
					dots = 0;
					fprintf('\n');
				end
			fflush(stdout);
			end
		end
		fprintf(' Done! \n\n');
		% Draw a 3D graphics for the adjustment results
		svm_G_adjustment(values,FScoreMatrix);
	
		% We chose the maximum value(s) of fscore and extract the values of C and sigma
		% for this value
		bestFScore = max(max(FScoreMatrix));
	
		[bestC, bestSigma] = find(bestFScore == FScoreMatrix);
	
		% Select the fist in case two or more sigma and C have the best accuracy
		C = bestC(1);
		sigma = bestSigma(1);
	end

	% We extract the model using the training examples and the selected values of C
	% and sigma
	model = svmTrain(X_tra, Y_tra, C,true, @(x1, x2)gaussianKernel(x1, x2, sigma,1e-3,10));
	svmPredict(model, X_val);
	
	% Report of the training:
	printf('\nSVM REPORT\n')
	printf('-------------------------------------------------------------------:\n')
	% Distribution
	printf('DISTRIBUTION:\n')
	printf('Training examples %d (%d%%)\n',rows(X_tra),percentage_training*100);
	if(adjusting)
		printf('Adjustment examples %d (%d%%)\n',rows(X_adj),percentage_adjustment*100);
		printf('Validation examples %d (%d%%)\n',rows(X_val),((1-(percentage_training +
		percentage_adjustment))*100));
	else
		printf('Validation examples %d (%d%%)\n',rows(X_val),(1-percentage_training)*100);
	end;
	if(adjusting)
		printf('-------------------------------------------------------------------:\n')
		% Adjustment results
		printf('ADJUSTMENT ANALYSIS\n')
		printf('Best value for C: %d\n',C);
		printf('Best Value for sigma: %d\n',sigma);
	end
	printf('-------------------------------------------------------------------:\n')
	% Report of the optimum values
	[precision,recall,fscore] = svm_precisionRecall(X_val, Y_val,model);
	printf('PRECISION-RECALL IN VALIDATION EXAMPLES:\n')
	printf('Precision: %f\n',precision);
	printf('Recall: %f\n',recall);
	printf('Fscore: %f\n',fscore);
	printf('-------------------------------------------------------------------:\n')
	
	hits = sum(svmPredict(model, X_tra) == Y_tra);
	printf('ACCURACY RESULTS (TRAINING EXAMPLES)\n')
	printf('Number of hits %d of %d\n',hits,rows(X_val));
	printf('Percentage of accuracy: %3.2f%%\n',(hits/rows(X_val))*100);
	printf('-------------------------------------------------------------------:\n')
	
	hits = sum(svmPredict(model, X_val) == Y_val);
	printf('ACCURACY RESULTS (VALIDATION EXAMPLES)\n')
	printf('Number of hits %d of %d\n',hits,rows(X_val));
	printf('Percentage of accuracy: %3.2f%%\n',(hits/rows(X_val))*100);
	printf('-------------------------------------------------------------------:\n')
end

%==============================================================================

% Function to extract the precision and the recall of a trained model given a
% threshold
function [precision,recall,fscore] = svm_precisionRecall(X, y,model)
	pred_y = svmPredict(model,X); % Get the predicted y values

	% Precision calculation
	true_positives = sum(pred_y & y); % Logic AND to extract the predicted
										% positives that are true
	pred_positives = sum(pred_y);

	if (pred_positives != 0)
		precision = true_positives / pred_positives;
	else
		precision = 0;
	end

	% Recall calculation
	actual_positives = sum(y);
	test = [pred_y,y,pred_y&y];

	if (actual_positives != 0)
		recall = true_positives / actual_positives;
	else
		recall = 0;
	end

	%F-score calculation
	fscore =  (2*precision*recall) / (precision + recall);
end

%==============================================================================

%{
	SVMTRAIN Trains an SVM classifier using a simplified version of the SMO 
	algorithm.
	[model] = SVMTRAIN(X, Y, C, kernelFunction, tol, max_passes) trains an
	SVM classifier and returns trained model. X is the matrix of training
	examples.  Each row is a training example, and the jth column holds the
	jth feature.  Y is a column matrix containing 1 for positive examples
	and 0 for negative examples.  C is the standard SVM regularization
	parameter.  tol is a tolerance value used for determining equality of
	floating point numbers. max_passes controls the number of iterations
	over the dataset (without changes to alpha) before the algorithm quits.
	
	Note: This is a simplified version of the SMO algorithm for training
	SVMs. In practice, if you want to train an SVM classifier, we
	recommend using an optimized package such as:
	LIBSVM   (http://www.csie.ntu.edu.tw/~cjlin/libsvm/)
	SVMLight (http://svmlight.joachims.org/)
%}
function [model] = svmTrain(X, Y, C,output, kernelFunction,...
							tol, max_passes)
	if ~exist('tol', 'var') || isempty(tol)
		tol = 1e-3;
	end
	
	if ~exist('max_passes', 'var') || isempty(max_passes)
		max_passes = 5;
	end
	
	% Data parameters
	m = size(X, 1);
	n = size(X, 2);
	
	% Map 0 to -1
	Y(Y==0) = -1;
	
	% Variables
	alphas = zeros(m, 1);
	b = 0;
	E = zeros(m, 1);
	passes = 0;
	eta = 0;
	L = 0;
	H = 0;
	
	% Pre-compute the Kernel Matrix since our dataset is small
	% (in practice, optimized SVM packages that handle large datasets
	%  gracefully will _not_ do this)
	%
	% We have implemented optimized vectorized version of the Kernels here so
	% that the svm training will run faster.
	if strcmp(func2str(kernelFunction), 'linearKernel')
		% Vectorized computation for the Linear Kernel
		% This is equivalent to computing the kernel on every pair of examples
		K = X*X';
	elseif strfind(func2str(kernelFunction), 'gaussianKernel')
		% Vectorized RBF Kernel
		% This is equivalent to computing the kernel on every pair of examples
		X2 = sum(X.^2, 2);
		K = bsxfun(@plus, X2, bsxfun(@plus, X2', - 2 * (X * X')));
		K = kernelFunction(1, 0) .^ K;
	else
		% Pre-compute the Kernel Matrix
		% The following can be slow due to the lack of vectorization
		K = zeros(m);
		for i = 1:m
			for j = i:m
				 K(i,j) = kernelFunction(X(i,:)', X(j,:)');
				 K(j,i) = K(i,j); %the matrix is symmetric
			end
		end
	end
	
	% Train
	if(output)
		fprintf('\nTraining ...');
		dots = 12;
	endif
	while passes < max_passes,
	
		num_changed_alphas = 0;
		for i = 1:m,
	
			% Calculate Ei = f(x(i)) - y(i) using (2).
			% E(i) = b + sum (X(i, :) * (repmat(alphas.*Y,1,n).*X)') - Y(i);
			E(i) = b + sum (alphas.*Y.*K(:,i)) - Y(i);
	
			if ((Y(i)*E(i) < -tol && alphas(i) < C) || (Y(i)*E(i) > tol && alphas(i) > 0)),
	
				% In practice, there are many heuristics one can use to select
				% the i and j. In this simplified code, we select them randomly.
				j = ceil(m * rand());
				while j == i,  % Make sure i \neq j
					j = ceil(m * rand());
				end
	
				% Calculate Ej = f(x(j)) - y(j) using (2).
				E(j) = b + sum (alphas.*Y.*K(:,j)) - Y(j);
	
				% Save old alphas
				alpha_i_old = alphas(i);
				alpha_j_old = alphas(j);
	
				% Compute L and H by (10) or (11).
				if (Y(i) == Y(j)),
					L = max(0, alphas(j) + alphas(i) - C);
					H = min(C, alphas(j) + alphas(i));
				else
					L = max(0, alphas(j) - alphas(i));
					H = min(C, C + alphas(j) - alphas(i));
				end
	
				if (L == H),
					% continue to next i.
					continue;
				end
	
				% Compute eta by (14).
				eta = 2 * K(i,j) - K(i,i) - K(j,j);
				if (eta >= 0),
					% continue to next i.
					continue;
				end
	
				% Compute and clip new value for alpha j using (12) and (15).
				alphas(j) = alphas(j) - (Y(j) * (E(i) - E(j))) / eta;
	
				% Clip
				alphas(j) = min (H, alphas(j));
				alphas(j) = max (L, alphas(j));
	
				% Check if change in alpha is significant
				if (abs(alphas(j) - alpha_j_old) < tol),
					% continue to next i.
					% replace anyway
					alphas(j) = alpha_j_old;
					continue;
				end
	
				% Determine value for alpha i using (16).
				alphas(i) = alphas(i) + Y(i)*Y(j)*(alpha_j_old - alphas(j));
	
				% Compute b1 and b2 using (17) and (18) respectively.
				b1 = b - E(i) ...
					 - Y(i) * (alphas(i) - alpha_i_old) *  K(i,j)' ...
					 - Y(j) * (alphas(j) - alpha_j_old) *  K(i,j)';
				b2 = b - E(j) ...
					 - Y(i) * (alphas(i) - alpha_i_old) *  K(i,j)' ...
					 - Y(j) * (alphas(j) - alpha_j_old) *  K(j,j)';
	
				% Compute b by (19).
				if (0 < alphas(i) && alphas(i) < C),
					b = b1;
				elseif (0 < alphas(j) && alphas(j) < C),
					b = b2;
				else
					b = (b1+b2)/2;
				end
	
				num_changed_alphas = num_changed_alphas + 1;
			end
		end
		if (num_changed_alphas == 0),
			passes = passes + 1;
		else
			passes = 0;
		end
		if (output)
			fprintf('.');
			dots = dots + 1;
			if dots > 78
				dots = 0;
				fprintf('\n');
			end
			if exist('OCTAVE_VERSION')
				fflush(stdout);
			end
		end
	end
	if (output)
		fprintf(' Done! \n\n');
	end;
	
	% Save the model
	idx = alphas > 0;
	model.X= X(idx,:);
	model.y= Y(idx);
	model.kernelFunction = kernelFunction;
	model.b= b;
	model.alphas= alphas(idx);
	model.w = ((alphas.*Y)'*X)';
end

%==============================================================================

%{
	SVMPREDICT returns a vector of predictions using a trained SVM model
	(svmTrain).
	pred = SVMPREDICT(model, X) returns a vector of predictions using a
	trained SVM model (svmTrain). X is a mxn matrix where there each
	example is a row. model is a svm model returned from svmTrain.
	predictions pred is a m x 1 column of predictions of {0, 1} values.
		
	Check if we are getting a column vector, if so, then assume that we only
	need to do prediction for a single example
%}
function pred = svmPredict(model, X)
	if (size(X, 2) == 1)
		% Examples should be in rows
		X = X';
	end
	
	% Dataset
	m = size(X, 1);
	p = zeros(m, 1);
	pred = zeros(m, 1);
	
	if strcmp(func2str(model.kernelFunction), 'linearKernel')
		% We can use the weights and bias directly if working with the
		% linear kernel
		p = X * model.w + model.b;
	elseif strfind(func2str(model.kernelFunction), 'gaussianKernel')
		% Vectorized RBF Kernel
		% This is equivalent to computing the kernel on every pair of examples
		X1 = sum(X.^2, 2);
		X2 = sum(model.X.^2, 2)';
		K = bsxfun(@plus, X1, bsxfun(@plus, X2, - 2 * X * model.X'));
		K = model.kernelFunction(1, 0) .^ K;
		K = bsxfun(@times, model.y', K);
		K = bsxfun(@times, model.alphas', K);
		p = sum(K, 2);
	else % Other Non-linear kernel
		for i = 1:m
			prediction = 0;
			for j = 1:size(model.X, 1)
				prediction = prediction + ...
					model.alphas(j) * model.y(j) * ...
					model.kernelFunction(X(i,:)', model.X(j,:)');
			end
			p(i) = prediction + model.b;
		end
	end
	
	% Convert predictions into 0 / 1
	pred(p >= 0) =  1;
	pred(p <  0) =  0;
end
