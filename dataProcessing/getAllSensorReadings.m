% script to loop over a list of all sensors (with possible duplicates)
% and get the unique rooms for a single floor
% they call python script to get data from BD

clear all
clc
BD_API_KEY='';
sensor='';
pat='Rm-2';
fp=fopen('listOfSensors.csv');

line=fgetl(fp);

roomNames={};
numRooms=0;
while (ischar(line)) 
    vec=mstrsplit(line,',');
    locName=vec{1};
    len=length(locName);
    flag=1;
    i=1;
    while((i<(len-2)) & flag)
        if locName(i:i+3)==pat
            strPt=i+3;
            flag=0;
        end
        i=i+1;
    end
    
    if (~flag)
        flag2=1;
        j=strPt;
        while ((j<len) & flag2)
            if locName(j)=='-'
                endPt=j-1;
                flag2=0;
            end
            j=j+1;
        end
        rmName=locName(strPt:endPt);
        difFlag=0;
        if (numRooms==0)
            difFlag=1;
        else
            difFlag=1;
            if length(rmName)==length(roomName{numRooms})
                if sum(rmName==roomName{numRooms})==length(rmName)
                    difFlag=0;
                end
            end
        end
        numRooms=numRooms+1;
        roomName{numRooms}=rmName;
        fprintf('%s\n',roomName{numRooms})
        if (difFlag)
            

            tic;
            com=['python fetchASensor.py ' BD_API_KEY ' ' roomName{numRooms} ' ' sensor '2014 01 01 2014 08 31'];
            system(com);
            
            toc
            %pause
        end
            
    end
    %line
    
    line=fgetl(fp);
end
        
        
        
        
        
