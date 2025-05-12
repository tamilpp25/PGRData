---@class XUiPcgPopupSettlement : XLuaUi
---@field private _Control XPcgControl
local XUiPcgPopupSettlement = XLuaUiManager.Register(XLuaUi, "UiPcgPopupSettlement")

function XUiPcgPopupSettlement:OnAwake()
    self:RegisterUiEvents()
end

function XUiPcgPopupSettlement:OnStart()
    self.StageId = self._Control.GameSubControl:GetLastStageId()
    self.StageRecord = self._Control.GameSubControl:GetLastStageRecord()
end

function XUiPcgPopupSettlement:OnEnable()
    self:Refresh()
end

function XUiPcgPopupSettlement:OnDisable()
    
end

function XUiPcgPopupSettlement:OnDestroy()
    
end

function XUiPcgPopupSettlement:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnLeave, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnAgain, self.OnBtnAgainClick)
    self:RegisterClickEvent(self.BtnNext, self.OnBtnNextClick)
end

function XUiPcgPopupSettlement:OnBtnCloseClick()
    self:Close()
    XLuaUiManager.Close("UiPcgGame")
end

function XUiPcgPopupSettlement:OnBtnAgainClick()
    local characters = self._Control.GameSubControl:GetLastCharacterIds()
    XMVCA.XPcg:PcgStageRestartRequest(self.StageId, characters, function()
        self:Close()
    end)
end

function XUiPcgPopupSettlement:OnBtnNextClick()
    local stageCfg = self._Control:GetConfigStage(self.NextStageId)
    if stageCfg.Type == XEnumConst.PCG.STAGE_TYPE.TEACHING then
        local characters = {0, 0, 0}
        if stageCfg.Type == XEnumConst.PCG.STAGE_TYPE.TEACHING then
            characters = self._Control:GetStageRecommendCharacterIds(self.NextStageId)
        else
            characters = self._Control.GameSubControl:GetLastCharacterIds()
        end
        XMVCA.XPcg:PcgStageBeginRequest(self.NextStageId, characters, function()
            self:Close()
        end)
    else
        local stageId = self.NextStageId
        local characters = self._Control.GameSubControl:GetLastCharacterIds()
        XLuaUiManager.CloseWithCallback(self.Name, function()
            XLuaUiManager.Open("UiPcgStageDetail", stageId, characters)
            XLuaUiManager.Remove("UiPcgGame")
        end)
    end
end

-- 刷新界面
function XUiPcgPopupSettlement:Refresh()
    self.PanelTarget.gameObject:SetActiveEx(false)
    self.PanelUnlockCharacter.gameObject:SetActiveEx(false)
    self.PanelRecord.gameObject:SetActiveEx(false)
    
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    if stageCfg.Type == XEnumConst.PCG.STAGE_TYPE.TEACHING 
    or stageCfg.Type == XEnumConst.PCG.STAGE_TYPE.NORMAL then
        self.NextStageId = self._Control:GetNextStageId(self.StageId)
        local isUnlock = XTool.IsNumberValid(self.NextStageId) and self._Control:IsStageUnlock(self.NextStageId) or false
        self.BtnNext.gameObject:SetActiveEx(isUnlock)
        self.BtnLeave.gameObject:SetActiveEx(not isUnlock)
        self:ShowPanelTarget()
        self:ShowPanelUnlockCharacter()
    else
        self.BtnNext.gameObject:SetActiveEx(false)
        self.BtnLeave.gameObject:SetActiveEx(true)
        self:ShowPanelRecord()
    end
    
    -- 胜利音效
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    ---@type XPcgCharacter
    local characterData = stageData:GetCharacter(XEnumConst.PCG.ATTACK_CHAR_INDEX)
    local charId = characterData:GetId()
    local finishCv = self._Control:GetCharacterFinishCv(charId)
    if XTool.IsNumberValid(finishCv) then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, finishCv)
    end
end

-- 显示三星目标面板
function XUiPcgPopupSettlement:ShowPanelTarget()
    self.PanelTarget.gameObject:SetActiveEx(true)

    self.TargetUiObjs = self.TargetUiObjs or {}
    self.GridTarget.gameObject:SetActiveEx(false)
    for _, targetUiObj in ipairs(self.TargetUiObjs) do
        targetUiObj.gameObject:SetActiveEx(false)
    end
    
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    local stars = self.StageRecord.Stars
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, desc in ipairs(stageCfg.StarDesc) do
        local targetUiObj = self.TargetUiObjs[i]
        if not targetUiObj then
            local go = CSInstantiate(self.GridTarget.gameObject, self.GridTarget.transform.parent)
            targetUiObj = go:GetComponent(typeof(CS.UiObject))
            table.insert(self.TargetUiObjs, targetUiObj)
        end
        targetUiObj.gameObject:SetActiveEx(true)
        local isActive = i <= stars
        targetUiObj:GetObject("TargetOn").gameObject:SetActiveEx(isActive)
        targetUiObj:GetObject("TargetOff").gameObject:SetActiveEx(not isActive)
        targetUiObj:GetObject("TxtTargetOn").text = desc
        targetUiObj:GetObject("TxtTargetOff").text = desc
    end
end

-- 显示解锁角色面板
function XUiPcgPopupSettlement:ShowPanelUnlockCharacter()
    local unlockCharacterIds = self._Control.GameSubControl:GetNewUnlockCharacterIds()
    local isShow = unlockCharacterIds and #unlockCharacterIds >0
    self.PanelUnlockCharacter.gameObject:SetActiveEx(isShow)
    if not isShow then return end

    self.CharacterUiObjs = self.CharacterUiObjs or {}
    self.GridCharacter.gameObject:SetActiveEx(false)
    for _, characterUiObj in ipairs(self.CharacterUiObjs) do
        characterUiObj.gameObject:SetActiveEx(false)
    end

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, characterId in ipairs(unlockCharacterIds) do
        local uiObj = self.CharacterUiObjs[i]
        if not uiObj then
            local go = CSInstantiate(self.GridCharacter.gameObject, self.GridCharacter.transform.parent)
            uiObj = go:GetComponent(typeof(CS.UiObject))
            table.insert(self.CharacterUiObjs, uiObj)
        end

        uiObj.gameObject:SetActiveEx(true)
        local characterCfg = self._Control:GetConfigCharacter(characterId)
        uiObj:GetObject("RImgHead"):SetRawImage(characterCfg.HeadIconCircle)
        uiObj:GetObject("ImgHeadRed").gameObject:SetActiveEx(characterCfg.ColorType == XEnumConst.PCG.COLOR_TYPE.RED)
        uiObj:GetObject("ImgHeadBlue").gameObject:SetActiveEx(characterCfg.ColorType == XEnumConst.PCG.COLOR_TYPE.BLUE)
        uiObj:GetObject("ImgHeadYellow").gameObject:SetActiveEx(characterCfg.ColorType == XEnumConst.PCG.COLOR_TYPE.YELLOW)
    end
end

-- 显示无尽关分数记录面板
function XUiPcgPopupSettlement:ShowPanelRecord()
    self.PanelRecord.gameObject:SetActiveEx(true)
    
    local round = self.StageRecord.MonsterLoop
    local score = self.StageRecord.Score
    local bestStageRecord = self._Control:GetActivityData():GetStageRecord(self.StageId)
    local isNew = bestStageRecord:GetIsNew()
    self.TxtRoundNum.text = tostring(round)
    self.TxtScoreNum.text = tostring(score)
    self.TagNew.gameObject:SetActiveEx(isNew)
end

return XUiPcgPopupSettlement
