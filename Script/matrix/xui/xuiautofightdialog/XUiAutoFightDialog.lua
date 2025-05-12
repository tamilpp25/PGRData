local XUiAutoFightDialog = XLuaUiManager.Register(XLuaUi, "UiAutoFightDialog")

local mathmin = math.min
local mathfloor = math.floor
local tableinsert = table.insert

local AnimBegin = "AniAutoFightDialogBegin"

function XUiAutoFightDialog:OnAwake()
    self:InitAutoScript()
    self:InitTemplate()
end

function XUiAutoFightDialog:OnStart(stageId)
    self:PlayAnimation(AnimBegin)

    self.TxtAutoFight.text = CS.XTextManager.GetText("AutoFightDialogTitle")
    self.TxtDescription.text = CS.XTextManager.GetText("AutoFightDialogDescription")

    self.StageId = stageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local autoFightCfg = XAutoFightConfig.GetCfg(stageCfg.AutoFightId)
    self.DailyLimit = stageCfg.MaxChallengeNums > 0 and stageCfg.MaxChallengeNums or autoFightCfg.DailyLimit

    local requireAP = XDataCenter.FubenManager.GetRequireActionPoint(stageId)
    local apId = XDataCenter.ItemManager.ItemId.ActionPoint
    local apCount = XDataCenter.ItemManager.GetCount(apId)
    local max = mathfloor(apCount / requireAP)
    local stageData = XDataCenter.FubenManager.GetStageData(stageId)
    local passTimesToday = stageData and stageData.PassTimesToday or 0
    local leftTimes = mathmin(max, self.DailyLimit - passTimesToday)

    self.RequireAP = requireAP
    self.LeftTimes = leftTimes
    self.TxtTimes.text = leftTimes
    self.RecordTime = stageData.LastRecordTime
    self:SetFightTimes(1)

    local cardIds = stageData.LastCardIds
    if stageCfg.RobotId and #stageCfg.RobotId > 0 then
        cardIds = {}
        for _,v in pairs(stageCfg.RobotId) do
            local charId = XRobotManager.GetCharacterId(v)
            tableinsert(cardIds, charId)
        end
    end
    self:InitCharacters(cardIds)
end

function XUiAutoFightDialog:InitTemplate()
    self.Template = self.PanelCharacters:Find("CharacterTemplate")
end

function XUiAutoFightDialog:InitCharacters(characterIds)
    local index = 0
    for _, id in pairs(characterIds) do
        if id > 0 then
            index = index + 1
            local transform
            if index == 1 then
                transform = self.Template
            else
                transform = CS.UnityEngine.Object.Instantiate(self.Template, self.PanelCharacters)
            end

            local img = transform:Find("RImgIcon"):GetComponent("RawImage")
            local icon = XMVCA.XCharacter:GetCharRoundnessHeadIcon(id)
            img:SetRawImage(icon)
        end
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiAutoFightDialog:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiAutoFightDialog:AutoInitUi()
    self.PanelAutoFightDialog = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog")
    self.PanelConsume = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelConsume")
    self.TxtTime = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelConsume/TxtTime"):GetComponent("Text")
    self.TxtTimes = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelConsume/TxtTimes"):GetComponent("Text")
    self.TxtConsume = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelConsume/TxtConsume"):GetComponent("Text")
    self.PanelTxt = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelTxt")
    self.TxtAutoFight = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelTxt/TxtAutoFight"):GetComponent("Text")
    self.TxtDescription = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelTxt/TxtDescription"):GetComponent("Text")
    self.PanelTeam = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelTeam")
    self.PanelCharacters = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelTeam/PanelCharacters")
    self.PanelBtn = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelBtn")
    self.TxtFightTimes = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelBtn/TxtFightTimes"):GetComponent("Text")
    self.BtnSub = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelBtn/BtnSub"):GetComponent("Button")
    self.BtnAdd = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelBtn/BtnAdd"):GetComponent("Button")
    self.BtnStart = self.Transform:Find("SafeAreaContentPane/PanelAutoFightDialog/PanelBtn/BtnStart"):GetComponent("Button")
    self.BtnClose = self.Transform:Find("SafeAreaContentPane/BtnClose"):GetComponent("Button")
end

function XUiAutoFightDialog:AutoAddListener()
    self:RegisterClickEvent(self.BtnSub, self.OnBtnSubClick)
    self:RegisterClickEvent(self.BtnAdd, self.OnBtnAddClick)
    self:RegisterClickEvent(self.BtnStart, self.OnBtnStartClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end
-- auto
function XUiAutoFightDialog:OnBtnCloseClick()
    self:Close()
end

function XUiAutoFightDialog:OnBtnSubClick()
    local tempTimes = self.FightTimes - 1
    if tempTimes < 1 then
        return
    end

    self:SetFightTimes(tempTimes)
end

function XUiAutoFightDialog:OnBtnAddClick()
    local tempTimes = self.FightTimes + 1
    if tempTimes > self.LeftTimes then
        return
    end

    self:SetFightTimes(tempTimes)
end

function XUiAutoFightDialog:OnBtnStartClick()
    if self.FightTimes == 0 then
        return
    end

    local stageId = self.StageId
    local times = self.FightTimes
    XDataCenter.AutoFightManager.StartAutoFight(stageId, times, function(res)
        if res.Code == XCode.Success then
            self:Close()
            XLuaUiManager.Open("UiAutoFightTip")
        end
    end)
end

function XUiAutoFightDialog:SetFightTimes(value)
    self.FightTimes = value
    self.TxtFightTimes.text = value
    self.TxtConsume.text = value * self.RequireAP
    self.TxtTime.text = XUiHelper.GetTime(self.RecordTime * value, XUiHelper.TimeFormatType.DRAW)
end