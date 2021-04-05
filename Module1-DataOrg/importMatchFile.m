function runNameMatchSheet1 = importMatchFile(filename, dataLines)
%IMPORTFILE Import data from a text file
%  RUNNAMEMATCHSHEET1 = IMPORTFILE(FILENAME) reads data from text file
%  FILENAME for the default selection.  Returns the data as a cell array.
%
%  RUNNAMEMATCHSHEET1 = IMPORTFILE(FILE, DATALINES) reads data for the
%  specified row interval(s) of text file FILENAME. Specify DATALINES as
%  a positive scalar integer or a N-by-2 array of positive scalar
%  integers for dis-contiguous row intervals.
%
%  Example:
%  runNameMatchSheet1 = importfile("/home/alexandresayal/GitRepos/DICOMtoSTCIBIT/runNameMatch - Sheet1.csv", [2, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 16-Dec-2020 19:26:10

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 3);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["originalName", "newName", "intenderFor"];
opts.VariableTypes = ["char", "char", "char"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["originalName", "newName", "intenderFor"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["originalName", "newName", "intenderFor"], "EmptyFieldRule", "auto");

% Import the data
runNameMatchSheet1 = readtable(filename, opts);

%% Convert to output type
runNameMatchSheet1 = table2cell(runNameMatchSheet1);
numIdx = cellfun(@(x) ~isnan(str2double(x)), runNameMatchSheet1);
runNameMatchSheet1(numIdx) = cellfun(@(x) {str2double(x)}, runNameMatchSheet1(numIdx));
end