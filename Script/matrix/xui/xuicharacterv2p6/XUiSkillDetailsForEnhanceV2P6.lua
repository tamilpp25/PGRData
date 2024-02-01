---@class XUiSkillDetailsForEnhanceV2P6 XUiSkillDetailsForEnhanceV2P6
---@field _Control XCharacterControl
local XUiSkillDetailsForEnhanceV2P6 = XLuaUiManager.Register(XLuaUi, "UiSkillDetailsForEnhanceV2P6")
local XUiPanelSkillDetailsInfoV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiPanelSkillDetailsInfoV2P6")

local CharacterTypeSkillGateIdDic = 
{
    [1] = 6,
    [2] = 5,
}

function XUiSkillDetailsForEnhanceV2P6:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.SkillPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnTog.gameObject:SetActiveEx(false)     --信号球技能（红黄蓝)
    self.BtnSpecial.gameObject:SetActiveEx(false)

    self.SkillBtnGrids = {}
    self:InitButton()
    self:InitPanel()
end

function XUiSkillDetailsForEnhanceV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnBtnNext)
    XUiHelper.RegisterClickEvent(self, self.BtnLast, self.OnBtnLast)
end

function XUiSkillDetailsForEnhanceV2P6:InitPanel()
    self.SkillInfoPanel = XUiPanelSkillDetailsInfoV2P6.New(self.PanelSkillInfo, self)
end

function XUiSkillDetailsForEnhanceV2P6:OnStart(characterId)
    self.CharacterId = characterId
    self.Character = XMVCA.XCharacter:GetCharacter(characterId)

    self:RecordViewPageAndTips()
end

-- 记录是否查看过该成员的跃升界面
function XUiSkillDetailsForEnhanceV2P6:RecordViewPageAndTips()
    local characterId = self.CharacterId

    if not XMVCA.XCharacter:CheckIsShowNewEnhanceTips(characterId) then
        return
    end

    self._Control:CharacterEnhanceSkillNoticeRequest(characterId, function ()
        local charFullName = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
        local title =  CS.XTextManager.GetText("EnhanceTip")
        local content = CS.XTextManager.GetText("StartEnhance", charFullName)
        XUiManager.PopupLeftTip(title, content)
    end)
end

function XUiSkillDetailsForEnhanceV2P6:OnEnable()
    self:RefreshUiShow()
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_FAST_TRADING, self.RefreshSkillDataByFastBuy, self)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.Coin, function()
        self:RefreshSkillDataByFastBuy()
    end, self.Transform)
end

function XUiSkillDetailsForEnhanceV2P6:RefreshUiShow()
    self:InitSkillBtn()
    self.PanelTagGroup:SelectIndex(self.CurrentSkillSelect or 1)

    -- 刷新技能类型文本
    local characterSkillGateConfig = XMVCA.XCharacter:GetModelCharacterSkillGate()
    local configId = CharacterTypeSkillGateIdDic[XMVCA.XCharacter:GetCharacterType(self.CharacterId)]
    local config = characterSkillGateConfig[configId]
    self.TxtName.text = config.Name
    self.TxtNameEn.text = config.EnName
    self.SkillIcon:SetRawImage(config.Icon)
end

function XUiSkillDetailsForEnhanceV2P6:InitSkillBtn()
    local tabGroup = {}
    local skillGroupIdList = self.Character:GetEnhanceSkillGroupIdList() or {}
    for index, skillGroupId in pairs(skillGroupIdList) do
        local btn = self.SkillBtnGrids[index]
        if not btn then
            local btnGo = XUiHelper.Instantiate(self.BtnSpecial, self.PanelTagGroup.transform)
            btn = btnGo:GetComponent("XUiButton")
            self.SkillBtnGrids[index] = btn
        end
        btn.gameObject:SetActiveEx(true)
        btn.transform:SetAsLastSibling()
        tabGroup[index] = btn

        local skillGroup = self.Character:GetEnhanceSkillGroupData(skillGroupId)
        -- 刷新按钮对应的技能信息
        btn:SetSprite(skillGroup:GetIcon())
        local level = skillGroup:GetLevel()
        local levelStr = level <= 0 and "" or CS.XTextManager.GetText("HostelDeviceLevel") .. ':' .. level
        btn:SetNameByGroup(0, levelStr)

        local IsPassCondition,_ = XMVCA.XCharacter:GetEnhanceSkillIsPassCondition(skillGroup, self.CharacterId)
        local IsShowRed = IsPassCondition and XMVCA.XCharacter:CheckEnhanceSkillIsCanUnlockOrLevelUp(skillGroup)
        btn:ShowReddot(IsShowRed)

        local ImgLocks = {
            btn.transform:Find("Normal/ImgLcok"),
            btn.transform:Find("Press/ImgLcok"),
            btn.transform:Find("Select/ImgLcok"),
        }
        local isLock = not skillGroup:GetIsUnLock()
        for _, lockGo in pairs(ImgLocks) do
            if lockGo then
                lockGo.gameObject:SetActiveEx(isLock)
            end
        end
    end
    self.PanelTagGroup:Init(tabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiSkillDetailsForEnhanceV2P6:OnBtnBackClick()
    self.ParentUi:Close()
end

function XUiSkillDetailsForEnhanceV2P6:OnClickTabCallBack(index)
    self.SkillInfoPanel:Refresh(index)
    self.CurrentSkillSelect = index
end

function XUiSkillDetailsForEnhanceV2P6:RefreshSkillDataByFastBuy()
    self.SkillInfoPanel:Refresh(self.CurrentSkillSelect)
end

-- 下一个
function XUiSkillDetailsForEnhanceV2P6:OnBtnNext()
    self.ParentUi:SetSkillPos(1)
end

-- 上一个
function XUiSkillDetailsForEnhanceV2P6:OnBtnLast()
    self.ParentUi:SetSkillPos(XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS)
end

function XUiSkillDetailsForEnhanceV2P6:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_FAST_TRADING, self.RefreshSkillDataByFastBuy, self)
    XDataCenter.ItemManager.RemoveCountUpdateListener(self.Transform)
end

return XUiSkillDetailsForEnhanceV2P6