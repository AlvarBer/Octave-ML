1;

%{
	Function in charge of loading data for BINARY classification in memory
	Just need to have the Y column as the last column.
	This function rearrange the data in positive and negative examples and returns
	two sets (positive (1) or negative (0))
%}
function [posExamples, negExamples] = getData(file, percentageData)

	if ~exist(file, type='file')
		error('Input file doesn''t exists')
	end

	printf('Loading data...');
	fflush(stdout);

	% Loads the raw data (normal or lite) from the data folder
	DATA = importdata(file,',',1);

	% Separate the parts of the CSV file
	data = DATA.data;
	textdata = DATA.textdata;
	colheaders = DATA.colheaders;

	% Sort the rows in positive/negative values (Y column is last column)
	data = sortrows(data,columns(data));

	% Saves the positive examples in posExamples
	posExamples = data(data(:,columns(data))==1,:);

	% Saves the negative examples in posExamples
	negExamples = data(data(:,columns(data))==0,:);

	% Permute randomly the order of the positive/negative examples
	posExamples = posExamples(randperm(size(posExamples,1)),:);
	negExamples = negExamples(randperm(size(negExamples,1)),:);

	% Total number of examples
	mPos = rows(posExamples);
	mNeg = rows(negExamples);

	% Get the proper percentage
	percentageData = percentageData;
	posExamples = posExamples(1:mPos*percentageData,:);
	negExamples = negExamples(1:mNeg*percentageData,:);
	printf('\nNumber of total positive examples: %i (%d %%)\n',mPos,(((mPos)/rows(data))*100));
	printf('Number of total negative examples: %i (%d %%)\n',mNeg,(((mNeg)/rows(data))*100));
	printf('Total number of examples: %i\n', rows(data));
	printf('Number of selected positive examples: %i (%d %%)\n',rows(posExamples),(((rows(posExamples))/rows(data))*100));
	printf('Number of selected negative examples: %i (%d %%)\n',rows(negExamples),(((rows(negExamples))/rows(data))*100));
	printf('Selected number of examples: %i\n\n', rows(posExamples) + rows(negExamples));
end

%{
	Filters a given matrix by a specific value on a given attribute:
%}
function filtered = filterByAttr(matrix, attribute, value)
	filtered = matrix(find(matrix(:,attribute) == value),:);
end