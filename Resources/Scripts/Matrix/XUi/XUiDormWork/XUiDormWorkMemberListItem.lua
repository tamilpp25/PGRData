local XUiDormWorkMemberListItem = XClass(nil, "XUiDormWorkMemberListItem")
local Mathf = math.floor
local MaxVitality = XDormConfig.DORM_VITALITY_MAX_VALUE
local SelectOne = 1
local SelectStates = {
    Add = 1,
    Reduce = -1
}
local TextManager = CS.XTextManager

function XUiDormWorkMemberListItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiDormWorkMemberListItem:Init(uiRoot, parent)
    self.UiRoot = uiRoot
    self.Parent = parent
end

-- 更新数据
function XUiDormWorkMemberListItem:OnRefresh(characterId)
    if not characterId then
        return
    end

    self.CurStata = self.Parent:IsExistWorkId(characterId)
    self:OnSetState(self.CurStata)
    self.CharacterId = characterId
    local icon = XDormConfig.GetCharacterStyleConfigQIconById(characterId)
    if icon then
        self.ImgIcon:SetRawImage(icon)
    end

    local eventtemp = XHomeCharManager.GetCharacterEvent(characterId, true)
    self.Events.gameObject:SetActiveEx(eventtemp)
    self.Vitality = XDataCenter.DormManager.GetVitalityById(characterId) or 0
    self.TxtVitCount.text = TextManager.GetText("DormWorkVitTxt", self.Vitality, MaxVitality)

    local mood = XDataCenter.DormManager.GetMoodById(characterId)
    local moodConfig = XDormConfig.GetMoodStateByMoodValue(mood)
    self.TxtValues.text = mood
    self.UiRoot:SetUiSprite(self.ImgMood, moodConfig.Icon)
end

function XUiDormWorkMemberListItem:OnBtnClick()
    self.CurStata = not self.CurStata
    self:OnSetState(self.CurStata)

    local cfg = XDataCenter.DormManager.GetWorkCfg()
    if not cfg then
        return
    end

    local vitaly = Mathf(cfg.Vitality / 100)

    local money = Mathf(self.Vitality / vitaly)

    if self.CurStata then
        if self.Vitality < 1 or money < 1 then
            self.CurStata = false
            self:OnSetState(false)
            XUiManager.TipText("DormWorkVitNotEn")
            return
        end

        self.TxtTime.text = XUiHelper.GetTime(Mathf(self.Vitality / vitaly) * cfg.Time, XUiHelper.TimeFormatType.HOSTEL)
        self.TxtVit.text = Mathf(self.Vitality / vitaly) * vitaly
        if self.Parent:IsFullMaxWorkCount() then
            XUiManager.TipText("DormWorkTips")
            self.CurStata = false
            self:OnSetState(false)
            return
        end

        self.Parent:UpdateWorkCountAndMoney(SelectOne, money, SelectStates.Add)
        self.Parent:RecordWorkIds(self.CharacterId)
    else
        self.Parent:UpdateWorkCountAndMoney(SelectOne, money, SelectStates.Reduce)
        self.Parent:RemoveWorkIds(self.CharacterId)
    end
end

function XUiDormWorkMemberListItem:OnSetState(state)
    self.ItemSele.gameObject:SetActive(state)
end

return XUiDormWorkMemberListItem