%FILE: delSim.m
%------------------------------------------------------------------------
%Description:
%Monte Carlo Simulation, given a specfic database to represent an mtg
%deck, to calculate the average number of turns required to attain
%delirium

%Assumptions:
%1. No interaction from the opponent including required actions from
%   opponent to obtain delerium
%2. Hands without a land are mulliganed
%3. Hands with 4 or more lands are mulliganed
%4. The sim will always choose the card sequences that acquire delerium in
%   the least number of turn cycles
%5. Assumes that all spells and lands are colorless

%Database Encoding:
%Type 0 : blank/irrelevant towards delirium based on prescribed assumptions
%Type 0.1 : land
%Type 1 : fetchland
%Type 2 : creature
%Type 3 : artifact
%Type 4 : sorcery
%Type 5 : instant

%Required Files:
%N/A
%------------------------------------------------------------------------
%INPUT: 
%   [DATABASE NAME].txt 
%   User prompted

%OUTPUT: 
%   results     Simulation results
%   plot        Graphical representation of simulation results
%------------------------------------------------------------------------

function [result] = delSim()
%                           ENVIRONMENT SETUP
%--------------------------------------------------------------------
    clc;
    disp('Delirium Turn Count Simulator')
    disp('--------------------------------------------');
    disp('Author: Christian Sargusingh')
    disp('Date: 2018-03-18')
    disp('--------------------------------------------');
    
    %import database
    str = uigetfile('*.txt');
    d = importdata(str);
    data = d.data();
    
    % Ask user for a number of random numbers to generate.
    userPrompt = 'Enter the number of simulation timesteps';
    timesteps = inputdlg(userPrompt, 'Enter an integer:',1,{'1000'});
    if isempty(timesteps)
        % User clicked cancel
        return;
    end
    timesteps = round(str2num(cell2mat(timesteps)));

    %temp code to fix sample size
    rem = 60 - length(data);
    %blanks represented as type 0
    data = padarray(data,rem,'post');
    
    %preallocate result matrix
    result = zeros(timesteps,2);
    mullTotal = 0;
    
    f = waitbar(0,'Please Wait','Name','Running Simulation...',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
    setappdata(f,'canceling',0);
    
%                         SIMULATION EVENT LOOP
%--------------------------------------------------------------------
    for j = 1 : timesteps
        % Check for cancel
        if getappdata(f,'canceling')
            break
        end
        %initialize the turn count
        turnCount = 0;
        %reset delirium flag
        delirium = 0;
        
        %Mulligan algorithm
        %rules: mulligan to 4 cards max
        %       mulligan hands with less than 1 land or more than 4 lands
        mull = 1;
        mullCount = 0;
        while mull
            landCount = 0;
            %function to generate a uniform distribution of 7 cards in the
            %opening hand
            index = randperm(60)';
            %No mulligan lower than 4 cards
            if mullCount < 3
                %load hand data using ud index and sort to ensure sequencing
                %cards are optimized to use the max number of different types
                hand = sort(data(index(1:7-mullCount),:),1);
            end
            %find the landcount
            if mullCount == 0
                for i = 1:7
                    if hand(i,2) == 0.1 || hand(i,2) == 1
                        landCount = landCount+1;
                    end
                end
            elseif mullCount == 1
                for i = 1:6
                    if hand(i,2) == 0.1 || hand(i,2) == 1
                        landCount = landCount+1;
                    end
                end
            elseif mullCount == 2
                for i = 1:5
                    if hand(i,2) == 0.1 || hand(i,2) == 1
                        landCount = landCount+1;
                    end
                end
            else
                for i = 1:4
                    if hand(i,2) == 0.1 || hand(i,2) == 1
                        landCount = landCount+1;
                        mullCount = 0;
                    end
                end
            end
            %recalculate mulligan count
            if landCount < 1 || landCount > 5
                mullTotal = mullCount + mullTotal;
            else
                break;
            end
        end
        %update waitbar
        waitbar(j/timesteps,f,sprintf('Mulligan Count: %i',mullTotal))
        
        %generate a table to display hand results
        cmc = hand(:,1);
        type = hand(:,2);
        sampleR = table(cmc,type);
        sampleR.Properties.VariableNames={'CMC','Type'};
        %Display accepted hand post mulligan decisions
        disp('Accepted Hand')
        disp('-------------------------------------------')
        disp(sampleR)
        while ~delirium
            %increase turn count
            turnCount = turnCount + 1;
            hand = sort(data(index(1:turnCount + 1 - mullCount),:),1);
            
            %only unique cards contribute to delirium
            [C,ia,ic] = unique(hand(:,2),'rows');
            hand = hand(ia,:);
            cmc = hand(:,1);
            type = hand(:,2);
            %generate a table to display hand results
            sample = table(cmc,type);
            sample.Properties.VariableNames={'CMC','Type'};
            %delirium check algorithm
            removed = 0;
            while ~removed
                %check if empty if so break out of the loop and draw
                if isempty(sample)
                    break
                end
                for i = 1 : height(sample)
                    %remove blanks
                    if sample{i,2} == 0 || sample{i,2} == 0.1
                       sample(i,:) = [];
                       break
                    else
                        removed = 1;
                    end
                end
            end
            
           
            
            %simplified hand
            disp('Simplified Hand')
            disp('--------------------------------------------')
            disp(sample)
            
            %check if the first simplified hand is length 1 if so deleirum
            %is unattainable with 1 card so we ignore the tests and
            %resample
            if height(sample) > 3
                if sample{height(sample),1} == 0
                    turn = 1;
                elseif sample{height(sample),1} == 1 && sample{height(sample)-1,1} ~= 1
                    turn = 1;
                elseif sample{height(sample),1} == 2 && sample{height(sample)-1,1} ~= 2
                    turn = 2;
                elseif sample{height(sample),1} == 3 && sample{height(sample)-1,1} ~= 3
                    turn = 3;
                else
                    turn = turnCount;
                end
            end
            %delirium check
            if height(sample) > 4 || height(sample) == 4
                delirium = 1;
            end
        end
        result(j,:) = [j,turn];
    end
    %remove waitbar
    delete(f);
    
    %                         DISPLAY RESULTS
    %--------------------------------------------------------------------
    plot(result(:,2));
    title('Simulation of Average Turn Count to Attain Delirium')
    xlabel('Timestep');
    ylabel('Turn to Delirium')
    hold on;
    m = round(mean(result(:,2)));
    l = line([0,timesteps],[m,m]);
    l.Color = [1 0 0];
    l.LineWidth = 1;
end
