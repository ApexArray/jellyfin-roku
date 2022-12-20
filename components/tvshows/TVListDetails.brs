sub init()
    m.title = m.top.findNode("title")
    m.title.text = tr("Loading...")
    m.options = m.top.findNode("tvListOptions")
    m.overview = m.top.findNode("overview")
    m.poster = m.top.findNode("poster")
    m.deviceInfo = CreateObject("roDeviceInfo")
    m.communityRating = m.top.findNode("communityRating")
    m.star = m.top.findNode("star")
    m.infoBar = m.top.findNode("infoBar")
    m.ratingGroup = m.top.findNode("rating")
    m.aired = m.top.findNode("aired")
    m.runtime = m.top.findNode("runtime")
    m.endtime = m.top.findNode("endtime")
    m.audio_codec = m.top.findNode("audio_codec")
    m.audio_codec_count = m.top.findnode("audio_codec_count")
    m.video_codec = m.top.findNode("video_codec")
end sub

sub itemContentChanged()
    item = m.top.itemContent
    itemData = item.json
    if itemData.indexNumber <> invalid
        indexNumber = itemData.indexNumber.toStr() + ". "
    else
        indexNumber = ""
    end if
    m.title.text = indexNumber + item.title
    m.overview.text = item.overview

    if itemData.PremiereDate <> invalid
        airDate = CreateObject("roDateTime")
        airDate.FromISO8601String(itemData.PremiereDate)
        m.aired.text = tr("Aired") + ": " + airDate.AsDateString("short-month-no-weekday")
    end if

    imageUrl = item.posterURL

    if get_user_setting("ui.tvshows.blurunwatched") = "true"
        if itemData.lookup("Type") = "Episode"
            if not itemData.userdata.played
                imageUrl = imageUrl + "&blur=15"
            end if
        end if
    end if

    m.poster.uri = imageUrl

    if type(itemData.RunTimeTicks) = "roInt" or type(itemData.RunTimeTicks) = "LongInteger"
        runTime = getRuntime()
        if runTime < 2
            m.runtime.text = "1 min"
        else
            m.runtime.text = stri(runTime).trim() + " mins"
        end if

        if get_user_setting("ui.design.hideclock") <> "true"
            m.endtime.text = tr("Ends at %1").Replace("%1", getEndTime())
        end if
    end if

    if itemData.communityRating <> invalid
        m.star.visible = true
        m.communityRating.text = str(int(itemData.communityRating * 10) / 10)
    else
        m.infoBar.removeChild(m.ratingGroup)
    end if

    videoIdx = invalid
    audioIdx = invalid

    if itemData.MediaStreams <> invalid
        for i = 0 to itemData.MediaStreams.Count() - 1
            if itemData.MediaStreams[i].Type = "Video" and videoIdx = invalid
                videoIdx = i
                m.video_codec.text = tr("Video") + ": " + itemData.mediaStreams[videoIdx].DisplayTitle
            else if itemData.MediaStreams[i].Type = "Audio" and audioIdx = invalid
                if item.selectedAudioStreamIndex > 1
                    audioIdx = item.selectedAudioStreamIndex
                else
                    audioIdx = i
                end if
                m.audio_codec.text = tr("Audio") + ": " + itemData.mediaStreams[audioIdx].DisplayTitle
            end if
            if videoIdx <> invalid and audioIdx <> invalid then exit for
        end for
    end if

    m.video_codec.visible = videoIdx <> invalid
    if audioIdx <> invalid
        m.audio_codec.visible = true
        DisplayAudioAvailable(itemData.mediaStreams)
    else
        m.audio_codec.visible = false
    end if
end sub

sub DisplayAudioAvailable(streams)

    count = 0
    for i = 0 to streams.Count() - 1
        if streams[i].Type = "Audio"
            count++
        end if
    end for

    if count > 1
        m.audio_codec_count.text = "+" + stri(count - 1).trim()
    end if

end sub

function getRuntime() as integer
    itemData = m.top.itemContent.json

    ' A tick is .1ms, so 1/10,000,000 for ticks to seconds,
    ' then 1/60 for seconds to minutess... 1/600,000,000
    return int(itemData.RunTimeTicks / 600000000.0)
end function

function getEndTime() as string
    itemData = m.top.itemContent.json
    date = CreateObject("roDateTime")
    duration_s = int(itemData.RunTimeTicks / 10000000.0)
    date.fromSeconds(date.asSeconds() + duration_s)
    date.toLocalTime()

    return formatTime(date)
end function

sub focusChanged()
    if m.top.itemHasFocus = true
        ' text to speech for accessibility
        if m.deviceInfo.IsAudioGuideEnabled() = true
            txt2Speech = CreateObject("roTextToSpeech")
            txt2Speech.Flush()
            txt2Speech.Say(m.title.text)
            txt2Speech.Say(m.overview.text)
        end if
    end if
end sub
