1;

source('logReg/lr_learningCurves.m');
source('logReg/lr_adjustment.m');
source('logReg/graphics.m');
source('extra/featureNormalize.m');
source('extra/sigmoidFunction.m');
warning('off');

% Main function of the logistic regression analysis
function [theta] = logReg(posExamples,negExamples,lCurves)
	%--------------------------------------------------------------------------
	% PARAMETERS
	normalize = false; % Normalize the data or not
	lambda = 0; % Regularization term (default)
	percentage_training = 0.65; % Training examples / Total examples
	adjusting = true; % Activates adjustment process
	threshold = 0.70; % Minimum degree of certainty required
	learningFreq = 0.001; % Adjust the learning rate (for learning curves)
	maxIterations = 2000; % Select the maximum number of iterations on training
	
	% ADJUSTMENT PARAMETERS (ONLY APPLIES IF adjusting = true)
	percentage_adjustment= 0.05; % Adjustment examples / Total examples
	lambdaValues = [0, 0.5, 1, 5, 10, 20, 50, 100, 500]; % Possible values for lambda
	%--------------------------------------------------------------------------
	
	%{ 
	Distribution of the examples (Positive and negative examples are equally
	 distributed) 
	%}
	
	%Number of features
	numFeatures = columns(posExamples);
	
	% Number of training examples
	n_tra_pos = fix(percentage_training * rows(posExamples));
	n_tra_neg =	fix(percentage_training * rows(negExamples));
	
	% Selection of training examples
	traExamples = [posExamples(1:n_tra_pos, :);negExamples(1:n_tra_neg, :)];
	
	% Permute the order of the training examples
	traExamples = traExamples(randperm(size(traExamples,1)), :);
	
	X_tra = traExamples(:, 1:numFeatures-1);
	Y_tra = traExamples(:, numFeatures);
	
	if (adjusting)
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
	
		%Selection of validation examples
		valExamples = [posExamples(n_tra_pos+n_adj_pos+1:rows(posExamples),:); ...
						negExamples(n_tra_neg+n_adj_neg+1:rows(negExamples),:)];
	
		  % Permute the order of the validation examples
		  valExamples = valExamples(randperm(size(valExamples,1)),:);
	
			if(normalize)
					X_adj = featureNormalize (X_adj);
			end
			Y_adj = adjExamples(:,numFeatures);
	
	else
		%Number of validation examples
		n_val_pos = rows(posExamples) - n_tra_pos;
		n_val_neg =	rows(negExamples) - n_tra_neg;
		valExamples = [posExamples(n_tra_pos+1:rows(posExamples),:);
						negExamples(n_tra_neg+1:rows(negExamples),:)];

		%Permute the order of the validation examples
		valExamples = valExamples(randperm(size(valExamples,1)),:);
	end
	
	X_val = valExamples(:,1:numFeatures-1);
	Y_val = valExamples(:,numFeatures);
	
	if (normalize)
		X_tra = featureNormalize (X_tra);
		X_val = featureNormalize (X_val);
	end
	
	% Adjustment process(Search of optimal lambda)
	if (adjusting)
		[bestLambda,errorAdj] = lr_adjustment (X_tra,Y_tra,X_adj,Y_adj,lambdaValues);
		lambda = bestLambda;
	end
	
	% Learning Curves + training or just training
	tic;
	if (lCurves)
		learningFreq = fix(rows(X_tra) * learningFreq);
		[errTraining, errValidation,theta] = lr_learningCurves (X_tra,Y_tra,X_val,Y_val,lambda,learningFreq);
	
		% Save/Load the result in disk (For debugging)
		save learningCurves.tmp errTraining errValidation theta;
		% load learningCurves.tmp
	
		% Show the graphics of the learning curves
		G_lr_LearningCurves(X_tra,errTraining, errValidation,learningFreq);
	else % Only Training
		theta = lr_training(X_tra,Y_tra,lambda,maxIterations);
	end

	ellapsedTime = toc;
	
	% Report of the training:
	printf('\nLOGISTIC REGRESSION REPORT\n')
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
	end
	if(adjusting)
		printf('-------------------------------------------------------------------:\n')
		printf('ADJUSTMENT ANALYSIS\n') % Adjustment results
		printf('Best value for lambda: %3.2f\n',bestLambda);
		printf('Error of the adjustment examples for the best lambda: %3.4f\n',errorAdj);
	end
	printf('-------------------------------------------------------------------:\n')
	% Error results
	printf('ERROR ANALYSIS:\n')
	tra_error = lr_getError(X_tra, Y_tra, theta);
	printf('Error in training examples: %f\n',tra_error);
	val_error = lr_getError(X_val, Y_val, theta);
	printf('Error in validation examples: %f\n',val_error);
	printf('Error difference: %f\n',val_error - tra_error);
	printf('-------------------------------------------------------------------:\n')
	
	% Report of the precision/recall results over the validation examples
	[precision,recall,fscore] = lr_precisionRecall(X_val, Y_val,theta,threshold);
	printf('PRECISION/RECALL RESULTS (USER-DEFINED THRESHOLD):\n')
	printf('Threshold: %f\n',threshold);
	printf('Precision: %f\n',precision);
	printf('Recall: %f\n',recall);
	printf('Fscore: %f\n',fscore);
	printf('-------------------------------------------------------------------:\n')
	
	[opt_threshold,precision,recall,fscore] = lr_optRP(X_val, Y_val,theta);
	printf('PRECISION/RECALL RESULTS (BEST F-SCORE):\n')
	printf('Optimum threshold: %f\n',opt_threshold);
	printf('Precision: %f\n',precision);
	printf('Recall: %f\n',recall);
	printf('Fscore: %f\n',fscore);
	printf('-------------------------------------------------------------------:\n')
	
	hits = sum( lr_prediction(X_val, theta, threshold) == Y_val);
	printf('ACCURACY RESULTS (USER-DEFINED THRESHOLD)\n')
	printf('Threshold: %f\n',threshold);
	printf('Number of hits: %d of %d\n',hits,rows(X_val));
	printf('Percentage of accuracy: %3.2f%%\n',(hits/rows(X_val))*100);
	printf('-------------------------------------------------------------------:\n')
	
	[opt_threshold,hits] = lr_optAccuracy(X_val, Y_val,theta);
	printf('ACCURACY RESULTS (BEST ACCURACY)\n')
	printf('Optimum threshold: %f\n',opt_threshold);
	printf('Number of hits %d of %d\n',hits,rows(X_val));
	printf('Percentage of accuracy: %3.2f%%\n',(hits/rows(X_val))*100);
	printf('-------------------------------------------------------------------:\n')
	printf('Time elapsed: %10.2f\n',ellapsedTime);
end

%==============================================================================

% Training function
function [theta,cost] = lr_training(X,y,lambda,maxIterations)
	m = length(y);
	n = length(X(1,:));

	X = [ones(m,1),X]; % Adding a column of ones to X

	initial_theta = zeros(n + 1, 1);
	theta = initial_theta;

	% Optimization
	options = optimset('GradObj','on','MaxIter',maxIterations);
	[theta,cost] = fminunc(@(t)(lr_costFunction(t,X,y,lambda)), ... 
	                       initial_theta,options);
end

%==============================================================================

% Cost Function
function [J,grad] = lr_costFunction (theta,X,y,lambda)
	warning ('off'); % Disable warnings

	m = length(y);
	n = length(X(1,:));
	J = ((1 / m) * sum(-y .* log(lr_hFunction(X,theta)) - (1 - y) .*
 	log (1 - lr_hFunction(X,theta))));
	regularizationTerm1 = (lambda/(2 * m)) * sum(theta .^ 2);

	J = J + regularizationTerm1;

	grad = (1 / m) .* sum((lr_hFunction(X,theta) - y) .* X);

	regularizationTerm2 = [0;lambda/m .* theta(2:n,:)];

	grad = grad + regularizationTerm2';

	grad = grad'; % Transpose the gradient because fmincg
end

%==============================================================================

% h Function
function [result] = lr_hFunction (X,theta)
	z = theta' * X';
	result = sigmoidFunction(z)';
end

%==============================================================================

% Function to classify examples
function prediction = lr_prediction(X, theta, threshold)
	m = length(X(:,1)); % Adding a column of ones to X
	X = [ones(m,1),X];

	prediction = lr_hFunction(X,theta);
  prediction = prediction > threshold;
end

%==============================================================================

% Function to extract the precision and the recall of a trained model given a
% threshold
function [precision,recall,fscore] = lr_precisionRecall(X, y,theta,threshold)
	pred_y = lr_prediction(X, theta,threshold); % Get the predicted y values

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

	% F-score calculation
	fscore = (2*precision*recall) / (precision + recall);
end

%==============================================================================

% Function to extract the optimum threshold that guarantees the best trade-off
% between precision and the recall of a trained model
function [opt_threshold,precision,recall,fscore] = lr_optRP(X, y,theta)
	for i = 1:100 % Try values from 0.01 to 1 in intervals of 0.01
		[precisions(i),recalls(i),fscores(i)] = lr_precisionRecall(X, y,theta,
			i/100);
	end

	% Select the best F-score and the threshold associated to it
	[max_Fscore, idx] = max(fscores);
	opt_threshold = (idx)/100;
	precision = precisions(idx);
	recall = recalls(idx);
	fscore = fscores(idx);
	[max_prec, idx_max_prec] = max(precisions);

	% Show the graphics of the recall-precision results
	G_lr_RecallPrecision(recalls,precisions,opt_threshold);
end

%==============================================================================

% Function to extract the optimum threshold that guarantees the maximum number
% of hits given a trained model over a set of examples
function [opt_threshold,max_hits] = lr_optAccuracy(X, y,theta)
	for i = 1:100 % Try values from 0.01 to 1 in intervals of 0.01
		[hits(i)] = sum( lr_prediction(X, theta, i/100) == y);
	end

	% Select the best F-score and the threshold associated to it
	[max_hits, idx] = max(hits);
	opt_threshold = (idx)/100;

	% Show the graphics of the recall-precision results
	G_lr_Accuracy(hits,opt_threshold,rows(X));
end

%==============================================================================
% Function to calculate the error produced by theta over a set of examples
function error= lr_getError(X, y, theta)
	m = rows(X);
	X = [ones(m,1),X];
	error =  lr_costFunction(theta,X,y,0);
end
