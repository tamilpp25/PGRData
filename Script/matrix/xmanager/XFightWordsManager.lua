XFightWordsManagerCreator = function()
    local XFightWordsManager = {}

    local XScheduleManagerScheduleOnce = XScheduleManager.ScheduleOnce
    local XScheduleManagerUnSchedule = XScheduleManager.UnSchedule
    local XEventId = XEventId
    local CsXGameEventManager = CS.XGameEventManager

    local TemplateId = nil
    local CurrentTemplate = nil
    local CurrentId = nil
    local MaxId = nil
    local ScheduleId = nil
    local CurAudioInfo = nil
    local NextTime
    local PauseTime

    function XFightWordsManager.Init()
        CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_FIGHT_PRE_CLEAR_UI, XFightWordsManager.OnFightExit)
    end

    function XFightWordsManager.OnFightExit()
        XFightWordsManager.Stop(true)
    end

    function XFightWordsManager.InitData()
        CurrentId = 0
        MaxId = #CurrentTemplate
    end

    local PlayNextWordFunc = function()
        XFightWordsManager.PlayNext()
    end

    function XFightWordsManager.Run(wordsId)
        if TemplateId then
            XFightWordsManager.Stop(true)
        end
        TemplateId = wordsId
        CurrentTemplate = XFightWordsConfigs.GetMovieCfg(wordsId)
        if not CurrentTemplate then
			XLog.Error("找不到wordsId,请检查 "..tostring(wordsId))
            return
        end
        XLuaUiManager.Open("UiFightWords")
        XFightWordsManager.InitData()
        XFightWordsManager.PlayNext()
    end

    function XFightWordsManager.UnSchedule()
        if ScheduleId then
            XScheduleManagerUnSchedule(ScheduleId)
            ScheduleId = nil
        end
    end

    function XFightWordsManager.Stop(isForce)
        if TemplateId then
            TemplateId = nil
            CurrentTemplate = nil
            CurrentId = nil
            PauseTime = nil
            NextTime = nil
            XFightWordsManager.UnSchedule()
            if isForce then
                XLuaUiManager.Remove("UiFightWords")
            else
                XLuaUiManager.Close("UiFightWords")
            end

            if CurAudioInfo then
                CurAudioInfo:Stop()
                CurAudioInfo = nil
            end
        end
    end

    function XFightWordsManager.Pause()
        if TemplateId then
            PauseTime = CS.UnityEngine.Time.time
            XFightWordsManager.UnSchedule()

            if CurAudioInfo then
                CurAudioInfo:Pause()
            end
        end
    end

    function XFightWordsManager.Resume()
        if TemplateId and PauseTime and NextTime then
            local duration = NextTime - PauseTime
            if (duration > 0) then
                duration = math.floor(duration * 1000)
                ScheduleId = XScheduleManagerScheduleOnce(PlayNextWordFunc, duration)
            end
            PauseTime = nil
            NextTime = nil

            if CurAudioInfo then
                CurAudioInfo:Resume()
            end
        end
    end

    -- local GetTotalDuration = function(tab)
    --     local duration = 0
    --     for _, t in ipairs(tab) do
    --         duration = duration + t
    --     end
    --     return duration
    -- end

    function XFightWordsManager.PlayNext()
        if not TemplateId and not CurrentTemplate then
            XLog.Warning("No Runnig Fight Words")
            return
        end
        CurrentId = CurrentId + 1
        if CurrentId > MaxId then
            XFightWordsManager.Stop()
            return
        end

        local Template = CurrentTemplate[CurrentId]
        local text = Template.Text
        -- local duration = math.floor(Template.Duration * 1000)
        -- NextTime = CS.UnityEngine.Time.time + Template.Duration
        local currentCvType = CS.XAudioManager.CvType
        local templateDuration = Template.Duration[currentCvType]
        local duration = math.floor(templateDuration * 1000)
        NextTime = CS.UnityEngine.Time.time + templateDuration
        XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_WORDS_NEXT, text)

        -- 音效
        local cvId = Template.CvId
        if cvId and cvId ~= 0 then
            if CurAudioInfo then
                CurAudioInfo:Stop()
            end
            CurAudioInfo = CS.XAudioManager.PlayCv(cvId)
        else
            CurAudioInfo = nil
        end

        XFightWordsManager.UnSchedule()
        ScheduleId = XScheduleManagerScheduleOnce(PlayNextWordFunc, duration)
    end

    XFightWordsManager.Init()
    return XFightWordsManager
end