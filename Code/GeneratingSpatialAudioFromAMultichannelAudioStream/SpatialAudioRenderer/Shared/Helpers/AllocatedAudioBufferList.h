/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An audio buffer list.
*/
#ifndef AllocatedAudioBufferList_h
#define AllocatedAudioBufferList_h

#import <AudioToolbox/AudioToolbox.h>

class AllocatedAudioBufferList
{
public:
    AllocatedAudioBufferList(UInt32 channelCount, uint16_t bufferSize)
    {
		
        mBufferList = static_cast<AudioBufferList *>(malloc(sizeof(AudioBufferList) + (sizeof(AudioBuffer) * channelCount)));
        mBufferList->mNumberBuffers = channelCount;
        for (UInt32 c = 0;  c < channelCount; ++c) {
            mBufferList->mBuffers[c].mNumberChannels = 1;
            mBufferList->mBuffers[c].mDataByteSize = bufferSize * sizeof(float);
            mBufferList->mBuffers[c].mData = malloc(sizeof(float) * bufferSize);
        }
    }
    
    AllocatedAudioBufferList(const AllocatedAudioBufferList&) = delete;
    
    AllocatedAudioBufferList& operator=(const AllocatedAudioBufferList&) = delete;
    
    ~AllocatedAudioBufferList()
    {
        if (mBufferList == nullptr) { return; }
        
        for (UInt32 i = 0; i < mBufferList->mNumberBuffers; ++i) {
            free(mBufferList->mBuffers[i].mData);
        }
        free(mBufferList);
        mBufferList = nullptr;
    }
    
    AudioBufferList * _Nonnull get()
    {
        return mBufferList;
    }
    
private:
    AudioBufferList * _Nonnull mBufferList  = { nullptr };
};

#endif /* AllocatedAudioBufferList_h */
