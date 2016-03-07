function main(file)
	source('preprocess/preprocessing.m');
	source('logReg/logReg.m');
	source('neuralNetwork/neuralNetwork.m');
	source('svm/svm.m');

	%ignore_function_time_stamp('all'); % This should speed up

	%------------------------------------------------------------------------------
	% PARAMETERS
	lCurves = false; % Generates learning curves for analyzing bias/variance
	dataPercentage = 100; % From 0 to 100, portion of raw data to load (1 is 100%)
	%------------------------------------------------------------------------------
	% NOTE: To use an algorithm, just uncomment its function
	
	% Extracts the data for classification
	[posExamples,negExamples] = getData(file, dataPercentage / 100);
	
	% Because in this case we will have two different estimators for the 
	% different kind of series we need to do some more preprocessing

	posSamples1 = filterByAttr(posExamples,1,1);
	negSamples1 = filterByAttr(negExamples,1,1);
	posSamples2 = filterByAttr(posExamples,1,2);
	negSamples2 = filterByAttr(negExamples,1,2);

	% Index Analysis using logistic regression
	%theta = logReg(posExamples,negExamples,lCurves);
	
	% Index Analysis using Neural networks
	%theta = neuralNetwork(posExamples,negExamples,lCurves);
	
	% Index Analysis using Support Vector Machines
	model = svm(posExamples,negExamples);
end
