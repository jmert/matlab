function resubmit_errjobs(jobs)
%resubmit_errjobs(jobs)
%
%Parse the cell array of jobs returned from FARMIT commands and resubmit any
%jobs which have ended in an error. This is determined by scanning the *.out
%for the string "Successfully completed", and if the line is not found, then
%the job is resubmitted. In this way, faults from Matlab crashing or the LSF
%scheduler can be resubmitted, but any captured errors which may have led to
%invalid output but a successfully terminated program will not be resubmitted
%since user intervetion is likely to be required.
%
%INPUTS
%  JOBS   A cell array of the jobs to possibly resubmit
%
%EXAMPLE
%  jobs = command_calling_farmit();
%  ...
%  resubmit_errjobs(jobs);
%

  % First identify whether the list of jobs still have their corresponding
  % *.mat files on disk. Select and keep only the jobs which exist.
  mask = cellfun(@(x) exist(x,'file')~=0, jobs);
  jobs = jobs(mask);

  % Now scan all the corresponding *.out files for the line "Successfully
  % completed".
  for i=1:length(jobs)
    % Construct the file name for the .out file
    outfile = [jobs{i}(1:end-3) 'out'];
    % Then grep it for the success line
    [r,s] = unix(['fgrep "Successfully completed" ' outfile]);
    % If fgrep returned 0, then the line was found, so move on to the next
    % output
    if r == 0
      continue
    end

    % Otherwise, resubmit the job
    farmit(jobs{i},'resubmit')
  end
end
