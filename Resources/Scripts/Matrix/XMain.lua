XMain = XMain or {}

XMain.IsWindowsEditor = CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor
local IsWindowsPlayer = CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer

XMain.IsDebug = CS.XRemoteConfig.Debug
XMain.IsEditorDebug = (XMain.IsWindowsEditor or IsWindowsPlayer) and XMain.IsDebug

local lockGMeta = {
    __newindex = function(t, k)
        XLog.Error("can't assign " .. k .." in _G")
    end,
    __index = function(t, k)
        XLog.Error("can't index " .. k .." in _G, which is nil")
    end
}

function LuaLockG()
    setmetatable(_G, lockGMeta)
end

local import = CS.XLuaEngine.Import

import("XCommon/XLog.lua")

XMain.Step1 = function()
    --打点
    CS.XRecord.Record("23000", "LuaXMainStart")

    if XMain.IsEditorDebug then
        require("XHotReload")
    end

    require("XCommon/XRpc")
    import("XCommon")
    import("XConfig")
    import("XOverseas/XConfig") -- 海外定制化目录
    require("XGame")
    import("XEntity")
    import("XOverseas/XEntity") -- 海外定制化目录
    import("XUi/XUiBase")
    import("XUi/XUiCommon/XScrollView")
    import("XBehavior")
    import("XGuide")
    require("XMovieActions/XMovieActionBase")
    CS.XApplication.SetProgress(0.52)
end


XMain.Step2 = function()
    import("XManager")
    import("XOverseas/XManager") -- 海外定制化目录
    import("XNotify")
    CS.XApplication.SetProgress(0.54)
end

XMain.Step3 = function()
    import("XUi/XUiArena")
    import("XUi/XUiArenaActivityResult")
    import("XUi/XUiArenaFightResult")
    import("XUi/XUiArenaLevelDetail")
    import("XUi/XUiArenaStage")
    import("XUi/XUiArenaTask")
    import("XUi/XUiArenaTeam")
    import("XUi/XUiArenaTeamRank")
    import("XUi/XUiArenaWarZone")
    import("XUi/XUiNewAutoFightDialog")
    import("XUi/XUiAutoFightList")
    import("XUi/XUiAutoFightReward")
    import("XUi/XUiAutoFightTip")
    import("XUi/XUiAwarenessTf")
    import("XUi/XUiBag")
    import("XUi/XUiBaseEquip")
    import("XUi/XUiBfrt")
    import("XUi/XUiBuyAsset")
    import("XUi/XUiCharacter")
    import("XUi/XUiCharacterDetail")
    import("XUi/XUiChatServe")
    import("XUi/XUiComeAcross")
    import("XUi/XUiCommon")
    import("XUi/XUiDialog")
    import("XUi/XUiDorm")
    import("XUi/XUiDraw")
    CS.XApplication.SetProgress(0.56)
end

XMain.Step4 = function()
    import("XUi/XUiEquip")
    import("XUi/XUiEquipAwarenessReplace")
    import("XUi/XUiEquipBreakThrough")
    import("XUi/XUiEquipDetail")
    import("XUi/XUiEquipReplace")
    import("XUi/XUiEquipReplaceNew")
    import("XUi/XUiEquipResonanceSelect")
    import("XUi/XUiEquipResonanceSkill")
    import("XUi/XUiEquipStrengthen")
    import("XUi/XUiFashion")
    import("XUi/XUiFavorability")
    import("XUi/XUiFightLoading")
    import("XUi/XUiFirstGetPopUp")
    import("XUi/XUiFuben")
    import("XUi/XUiFubenActivityBanner")
    import("XUi/XUiFubenActivityChapter")
    import("XUi/XUiFubenActivitySection")
    import("XUi/XUiFubenChallengeBanner")
    import("XUi/XUiFubenChallengeChapter")
    CS.XApplication.SetProgress(0.58)
end

XMain.Step5 = function()
    import("XUi/XUiFubenChallengeEMEX")
    import("XUi/XUiFubenChallengeHSJYQZ")
    import("XUi/XUiFubenChallengeMap")
    import("XUi/XUiFubenBossSingle")
    import("XUi/XUiFubenChallengeMapEmex")
    import("XUi/XUiFubenChallengeSection")
    import("XUi/XUiFubenChallengeUrgent")
    import("XUi/XUiFubenChallengeYSHTX")
    import("XUi/XUiFubenCoinSkill")
    import("XUi/XUiFubenDailyBanner")
    import("XUi/XUiFubenDailyChapter")
    import("XUi/XUiFubenDialog")
    import("XUi/XUiFubenFlopReward")
    import("XUi/XUiFubenMainLineBanner")
    import("XUi/XUiFubenMainLineChapter")
    import("XUi/XUiFubenMainLineChapterBanner")
    import("XUi/XUiFubenMainLineDetail")
    import("XUi/XUiFubenResourceDetail")
    import("XUi/XUiFubenStageDetail")
    import("XUi/XUiFubenStory")
    CS.XApplication.SetProgress(0.60)
end

XMain.Step6 = function()
    import("XUi/XUiFubenUrgentEventTip")
    import("XUi/XUiFunctionalOpen")
    import("XUi/XUiGameNotice")
    import("XUi/XUiGuide")
    import("XUi/XUiHomeMain")
    import("XUi/XUiHostelCharacterWork")
    import("XUi/XUiHostelDelegate")
    import("XUi/XUiHostelDelegateReporter")
    import("XUi/XUiHostelDeviceDetail")
    import("XUi/XUiHostelDeviceUpgradeResult")
    import("XUi/XUiHostelDeviceUpgrading")
    import("XUi/XUiHostelMissionComplete")
    import("XUi/XUiHostelQte")
    import("XUi/XUiHostelRest")
    import("XUi/XUiHostelRoom")
    import("XUi/XUiHud")
    import("XUi/XUiLogin")
    import("XUi/XUiLoginNotice")
    import("XUi/XUiMail")
    import("XUi/XUiMain")
    CS.XApplication.SetProgress(0.62)
end

XMain.Step7 = function()
    import("XUi/XUiMission")
    import("XUi/XUiMoneyReward")
    import("XUi/XUiMoneyRewardFightTipFind")
    import("XUi/XUiNewPlayerTask")
    import("XUi/XUiNewRoleShow")
    import("XUi/XUiNewRoomSingle")
    import("XUi/XUiNoticeTips")
    import("XUi/XUiObtain")
    import("XUi/XUiOnlineBoss")
    import("XUi/XUiOnlineBossResult")
    import("XUi/XUiOnLineTranscript")
    import("XUi/XUiOnLineTranscriptRoom")
    import("XUi/XUiPersonalInfo")
    import("XUi/XUiPlayer")
    import("XUi/XUiPlayerUp")
    import("XUi/XUiPrequel")
    import("XUi/XUiPrequelLineDetail")
    import("XUi/XUiRegister")
    import("XUi/XUiRoomCharacter")
    import("XUi/XUiRoomMul")
    CS.XApplication.SetProgress(0.65)
end

XMain.Step8 = function()
    import("XUi/XUiRoomTeamPrefab")
    import("XUi/XUiSet")
    import("XUi/XUiSettleLose")
    import("XUi/XUiSettleUrgentEvent")
    import("XUi/XUiSettleWin")
    import("XUi/XUiSettleWinMainLine")
    import("XUi/XUiSettleWinSingleBoss")
    import("XUi/XUiShop")
    import("XUi/XUiSkip")
    import("XUi/XUiSocial")
    import("XUi/XUiStory")
    import("XUi/XUiTask")
    import("XUi/XUiTest")
    import("XUi/XUiTip")
    import("XUi/XUiTipReward")
    import("XUi/XUiTower")
    import("XUi/XUiTrial")
    import("XHome")
    import("XScene")
    import("XUi")
    import("XOverseas/XUi") -- 海外定制化目录
    import("XMerge")
    CS.XApplication.SetProgress(0.68)
end

XMain.Step9 = function()
    LuaLockG()
    --打点
    CS.XRecord.Record("23008", "LuaXMainStartFinish")
end