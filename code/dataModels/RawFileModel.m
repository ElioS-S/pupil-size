classdef RawFileModel < handle
    % RawFileModel Class for managing the required raw file structure.
    %
    %   Use the constructor to create an instance, and initialize its
    %   properties:
    %
    %     obj = RawFileModel(diameterUnit,diameter,segmentsTable...
    %           [,zeroTime_ms[,filename]]);
    %
    %      diameterUnit is a char array stipulating the unit of the
    %      diameter data (e.g. mm).
    %
    %      diameter is a struct with a 't_ms' field containing a time
    %      vector, and 'L' and 'R' fields, containing the left and right
    %      pupil size vectors, respectively. t_ms, L and R must all be
    %      single column vectors with the same number of rows. Leave L or R
    %      empty if that pupil was not measured.
    %
    %      segmentsTable is a table indicating the start and end times of
    %      each segment, as well as the segment name. These data must be
    %      saved in as the table variables segmentStart, segmentEnd and
    %      segmentName. Additional metadata columns, such as the filename
    %      or segment specific conditions, can be saved as other variables,
    %      which will be appended to the results file when the analysis is
    %      run.
    %
    %      zeroTime_ms is an optional argument that sets the zeroTime_ms
    %      property of the object. The t_ms timevector should start at 0,
    %      which may not correspond to the timestamps in the raw data. The
    %      zeroTime_ms property is a place to store the eye-tracker
    %      timestamp (im ms) that corresponds to t=0. This property is not
    %      actually used to this package.
    %
    %      filename is an optional arguments that automatically triggers
    %      the saveMatFile method using the passed filename.
    %
    %    After object initialization, call the saveToMat method to save the
    %    data to a MAT file:
    %
    %     saveMatFile(obj,filename)
    %
    %    Use this class to ensure data compatibility with the
    %    PupilDataModel class.
    %
    %----------------------------------------------------------------------
    %
    %   This code is part of the supplement material to the article:
    %
    %    Preprocessing Pupil Size Data. Guideline and Code.
    %     Mariska Kret & Elio Sjak-Shie. 2018.
    %
    %----------------------------------------------------------------------
    %
    %     Pupil Size Preprocessing Code (v1.1)
    %      Copyright (C) 2018  Elio Sjak-Shie
    %       E.E.Sjak-Shie@fsw.leidenuniv.nl.
    %
    %     This program is free software: you can redistribute it and/or
    %     modify it under the terms of the GNU General Public License as
    %     published by the Free Software Foundation, either version 3 of
    %     the License, or (at your option) any later version.
    %
    %     This program is distributed in the hope that it will be useful,
    %     but WITHOUT ANY WARRANTY; without even the implied warranty of
    %     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    %     General Public License for more details.
    %
    %     You should have received a copy of the GNU General Public License
    %     along with this program.  If not, see
    %     <http://www.gnu.org/licenses/>.
    %
    %----------------------------------------------------------------------
    
    
    %% Properties:
    
    properties
        
        diameterUnit   = 'mm';
        diameter       = struct('t_ms',[],'L',[],'R',[]);
        zeroTime_ms    = [];
        segmentsTable  = dataset();
        
    end
    
    
    %% Methods:
    
    methods
        
        
        %===================================================================
        function obj = RawFileModel(diameterUnit,diameter,segmentsTable...
                ,zeroTime_ms,filename)
            % RawFileModel Constucts a RawFileModel instance.
            %
            %--------------------------------------------------------------
            
            % Parse and save inputs:
            if nargin>0
                obj.diameterUnit = diameterUnit;
            end
            if nargin>1
                obj.diameter = diameter;
            end
            if nargin>2
                obj.segmentsTable = segmentsTable;
            end
            if nargin>3
                obj.zeroTime_ms = zeroTime_ms;
            end
            if nargin>4
                obj.saveMatFile(filename);
            end
            
        end
        
        
        %===================================================================
        function set.diameter(obj,valIn)
            % Sets the diameter property
            %
            %--------------------------------------------------------------
            
            % Check input:
            assert(all(ismember(fieldnames(valIn),{'t_ms' 'L' 'R'}))...
                ,['The diameter struct must contain the'...
                ' ''t_ms'', ''L'' and ''R'' fields.']);
            assert(isempty(valIn.t_ms)||isvector(valIn.t_ms)...
                ,'''t_ms'' must be a vector.');
            assert(isempty(valIn.L)||isvector(valIn.L)...
                ,'''L'' must be a vector, or be empty.');
            assert(isempty(valIn.R)||isvector(valIn.R)...
                ,'''R'' must be a vector, or be empty.');
            assert(isempty(valIn.L)||length(valIn.t_ms)==length(valIn.L)...
                ,['''L'' must be empty, or have the same'...
                ' length as ''t_ms''.']);
            assert(isempty(valIn.R)||length(valIn.t_ms)==length(valIn.R)...
                ,['''R'' must be empty, or have the same'...
                ' length as ''t_ms''.']);
            assert(isempty(valIn.t_ms)||issorted(valIn.t_ms)...
                ,'t_ms must be sorted!')
            obj.diameter = valIn;
            
        end
        
        
        %===================================================================
        function saveMatFile(obj,filename)
            % saveMatFile Saves the object to a MAT file with the specified
            % filename:
            %
            %   saveMatFile(obj,filename);
            %
            %--------------------------------------------------------------
            
            if ~isempty(obj.diameter)
                s = struct(...
                    'diameter',obj.diameter...
                    ,'diameterUnit',obj.diameterUnit...
                    ,'zeroTime_ms',obj.zeroTime_ms...
                    ,'segmentsTable',obj.segmentsTable); %#ok<NASGU>
                save(filename,'-struct','s');
            end
            
        end
        
    end
    
end


