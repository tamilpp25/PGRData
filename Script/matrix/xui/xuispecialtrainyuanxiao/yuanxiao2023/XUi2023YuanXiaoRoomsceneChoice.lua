local XUi2023YuanXiaoRoomsceneChoiceGrid = require("XUi/XUiSpecialTrainYuanXiao/YuanXiao2023/XUi2023YuanXiaoRoomsceneChoiceGrid")

---@class XUi2023YuanXiaoRoomsceneChoice:XLuaUi
local XUi2023YuanXiaoRoomsceneChoice = XLuaUiManager.Register(XLuaUi, "Ui2023YuanXiaoRoomsceneChoice")

function XUi2023YuanXiaoRoomsceneChoice:Ctor()
    ---@type XUi2023YuanXiaoRoomsceneChoiceGrid[]
    self._GridList = {}
    self._SkillSelected = false
end

function XUi2023YuanXiaoRoomsceneChoice:OnEnable()
    self:UpdateEquip()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_YUANXIAO_UPDATE_SKILL, self.UpdateEquip, self)
end

function XUi2023YuanXiaoRoomsceneChoice:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_YUANXIAO_UPDATE_SKILL, self.UpdateEquip, self)
end

function XUi2023YuanXiaoRoomsceneChoice:OnAwake()
    self:BindExitBtns(self.BtnTanchuangClose)
    self:RegisterClickEvent(self.BtnTongBlue, function()
        if not self._SkillSelected then
            return
        end
        if XDataCenter.FubenSpecialTrainManager.SetYuanXiaoSkill(self._SkillSelected.Id) then
            self:Close()
        end
    end)
end

function XUi2023YuanXiaoRoomsceneChoice:OnStart()
    self:InitSkill()
end

function XUi2023YuanXiaoRoomsceneChoice:InitSkill()
    local allSkill = XFubenSpecialTrainConfig.GetAllYuanXiaoSkill()
    local firstSkill
    for id, skill in pairs(allSkill) do
        local uiGrid = CS.UnityEngine.Object.Instantiate(self.GridScene, self.GridScene.parent.transform)
        local grid = XUi2023YuanXiaoRoomsceneChoiceGrid.New(uiGrid)
        grid:Update(skill)
        grid:RegisterClick(function(data)
            self:OnGridClick(data)
        end)
        self._GridList[#self._GridList + 1] = grid
        firstSkill = firstSkill or skill
    end
    self.GridScene.gameObject:SetActiveEx(false)
    self._SkillSelected = XDataCenter.FubenSpecialTrainManager.GetYuanXiaoSkill() or firstSkill
    self:UpdateSelected()
end

function XUi2023YuanXiaoRoomsceneChoice:UpdateSelected()
    for i = 1, #self._GridList do
        local grid = self._GridList[i]
        grid:UpdateSelected(self._SkillSelected)
    end
    self:Update()
end

function XUi2023YuanXiaoRoomsceneChoice:OnGridClick(data)
    self._SkillSelected = data
    self:UpdateSelected()
end

function XUi2023YuanXiaoRoomsceneChoice:Update()
    local data = self._SkillSelected
    self.TxtTipName.text = data.Name
    self.TxtTipDesc.text = XUiHelper.ReplaceTextNewLine(data.Desc)
    self.RImgIcon:SetRawImage(data.Icon)
    local skillEquip = XDataCenter.FubenSpecialTrainManager.GetYuanXiaoSkill()
    if skillEquip == data then
        self.BtnTongBlue:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnTongBlue:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUi2023YuanXiaoRoomsceneChoice:UpdateEquip()
    local skillEquip = XDataCenter.FubenSpecialTrainManager.GetYuanXiaoSkill()
    for i = 1, #self._GridList do
        local grid = self._GridList[i]
        grid:UpdateEquip(skillEquip)
    end
end

return XUi2023YuanXiaoRoomsceneChoice