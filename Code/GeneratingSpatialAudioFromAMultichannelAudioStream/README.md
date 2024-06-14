# Generating spatial audio from a multichannel audio stream
Convert 8-channel audio to 2-channel spatial audio by using a spatial mixer audio unit.


## Overview
Spatial audio makes sound seem like it's coming from all around you. To generate spatialized audio from a multichannel audio stream, you use a spatial mixer audio unit (AUSM). The audio streams can come from the output of a game engine, video player, or audio file. 

The sample app shows you how to create an AUSM, and how to configure its channel layout and stream format. It streams multichannel input from an audio file, and down-mixes it to 2-channel spatial audio. 

## Create an audio unit spatial mixer
The sample uses the pull model to get the input from an in-memory file streamer. The `OutputAU` class pulls input from the `AudioKernel`, which manages the AUSM. The AUSM pulls audio from `AudioFileReader` to get input. On macOS, the output unit uses [`kAudioUnitSubType_HALOutput`][0] to interface with the audio device. On iOS, the interface is configured as  [`kAudioUnitSubType_RemoteIO`][1].

To begin setup of an AUSM, the sample initializes a mixer with a subtype of [`kAudioUnitSubType_SpatialMixer`][2].

``` objective-c
AudioComponentDescription auDescription = {kAudioUnitType_Mixer,
                                           kAudioUnitSubType_SpatialMixer,
                                           kAudioUnitManufacturer_Apple,
                                           0,
                                           0};
AudioComponent comp = AudioComponentFindNext(NULL, &auDescription);
assert(comp);

OSStatus err = AudioComponentInstanceNew(comp, &mAU);
assert(err == noErr);
```

After initializing the spatial mixer, the sample calls a convenience function to configure the output stream format and channel layout for stereo audio. 

``` objective-c
err = setStreamFormatAndACL(inOutputSampleRate, kAudioChannelLayoutTag_Stereo, kAudioUnitScope_Output, 0);
assert(err == noErr);
```

The sample then configures the input stream format and sets the channel layout to  [`kAudioChannelLayoutTag_MPEG_7_1_A`][3]  for 8-channel audio.

``` objective-c
err = setStreamFormatAndACL(inInputSampleRate,
                            kAudioChannelLayoutTag_Atmos_7_1_4,
                            kAudioUnitScope_Input,
                            elem);
assert(err == noErr);
```

## Configure for spatial audio 
The sample sets the spatialization algorithm to [`kSpatializationAlgorithm_UseOutputType`][4] for the highest-quality spatial rendering across different hardware.
    
``` objective-c
UInt32 renderingAlgorithm = kSpatializationAlgorithm_UseOutputType;
err = AudioUnitSetProperty(mAU,
                           kAudioUnitProperty_SpatializationAlgorithm,
                           kAudioUnitScope_Input,
                           elem,
                           &renderingAlgorithm,
                           sizeof(renderingAlgorithm));
assert(err == noErr);
```
    
The input channels are spatialized around the listener as far-field sources. The channel layout specifies the relative directions of the individual channels. The azimuth and elevation parameters control the audio rotation. The sample configures the source mode to [`kSpatialMixerSourceMode_AmbienceBed`][5]. Use [`kSpatialMixerSourceMode_PointSource`][6] for an object to render the input signal as a single source, except if rendering in-head with [`kSpatialMixerPointSourceInHeadMode_Bypass`][7].

``` objective-c
UInt32 sourceMode = kSpatialMixerSourceMode_AmbienceBed;
err = AudioUnitSetProperty(mAU, kAudioUnitProperty_SpatialMixerSourceMode, kAudioUnitScope_Input, elem, &sourceMode, sizeof(sourceMode));
assert(err == noErr);
```

Spatial audio includes dynamic head tracking for apps that enable it. To configure head tracking, set [`kAudioUnitProperty_SpatialMixerEnableHeadTracking`][8]. For more information about supported devices, see [Listen with spatial audio for AirPods and Beats][9].

``` objective-c
UInt32 ht = 1;
err = AudioUnitSetProperty(mAU,
                           kAudioUnitProperty_SpatialMixerEnableHeadTracking,
                           kAudioUnitScope_Global,
                           0,
                           &ht,
                           sizeof(UInt32));
```

[0]: https://developer.apple.com/documentation/audiotoolbox/kaudiounitsubtype_haloutput
[1]: https://developer.apple.com/documentation/audiotoolbox/kaudiounitsubtype_remoteio
[2]: https://developer.apple.com/documentation/audiotoolbox/kaudiounitsubtype_spatialmixer
[3]: https://developer.apple.com/documentation/coreaudiotypes/kaudiochannellayouttag_mpeg_7_1_a
[4]: https://developer.apple.com/documentation/audiotoolbox/auspatializationalgorithm/kspatializationalgorithm_useoutputtype?changes=__5&language=objc
[5]: https://developer.apple.com/documentation/audiotoolbox/auspatialmixersourcemode/kspatialmixersourcemode_ambiencebed?language=objc
[6]: https://developer.apple.com/documentation/audiotoolbox/auspatialmixersourcemode/kspatialmixersourcemode_pointsource?language=objc
[7]: https://developer.apple.com/documentation/audiotoolbox/auspatialmixerpointsourceinheadmode/kspatialmixerpointsourceinheadmode_bypass?language=objc
[8]: https://developer.apple.com/documentation/audiotoolbox/1534150-spatial_mixer_property_ids/kaudiounitproperty_spatialmixerenableheadtracking
[9]: https://support.apple.com/en-us/HT211775
