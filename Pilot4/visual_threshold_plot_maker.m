%% This script runs the visual threshold part of the fourth pilot.

figure()
%% Plot the psychometric function and save all variables

ix=(q.intensity~=0);  %keep the desired indices
plot(q.intensity(ix), 'Color', [0.6350 0.0780 0.1840]) % plot only those particular ones
%plot(contrastArray);


%% Plot the psychometric function and save all variables

figure()
plot(q120.intensity(ix120)) % plot only those particular ones
hold on
plot(q80.intensity(ix80))
