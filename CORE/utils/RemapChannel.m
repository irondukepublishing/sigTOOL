function RemapChannel(channel)

% Copy the memmapfile propery settings
Filename=channel.adc.Map.Filename;
Writable=channel.adc.Map.Writable;
Offset=channel.adc.Map.Offset;
Format=channel.adc.Map.Format;
Repeat=channel.adc.Map.Repeat;

% Reinitialize the map - no virtual memory will be allocated until an
% attempt is made to access data in the new object
channel.adc.Map=memmapfile(Filename,...
    'Writable', Writable,...
    'Offset', Offset,...
    'Format', Format,...
    'Repeat', Repeat);
end

