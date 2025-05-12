---@class XUiMaverick3Handbook : XLuaUi 孤胆枪手图鉴
---@field _Control XMaverick3Control
local XUiMaverick3Handbook = XLuaUiManager.Register(XLuaUi, "UiMaverick3Handbook")

function XUiMaverick3Handbook:OnAwake()
    ---@type XTableMaverick3Talent[]
    self._OrnamentsDatas = {}
    ---@type XTableMaverick3Talent[]
    self._SlayDatas = {}
    ---@type XUiGridMaverick3Ornaments[]
    self._OrnamentsGrids = {}
    ---@type XUiGridMaverick3Slay[]
    self._SlayGrids = {}

    self.BtnUnlock.CallBack = handler(self, self.OnBtnUnlockClick)
    self.BtnEquip.CallBack = handler(self, self.OnBtnEquipClick)
end

function XUiMaverick3Handbook:OnStart(characterIndex, selectId)
    self._CharacterIndex = characterIndex or self._Control:GetFightIndex()
    self._DefaultSelectId = selectId

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end, nil, 0)

    local ItemIds = { XEnumConst.Maverick3.Currency.Cultivate, XEnumConst.Maverick3.Currency.Shop }
    XUiHelper.NewPanelActivityAssetSafe(ItemIds, self.PanelSpecialTool, self)
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)

    ---@type XUiGridMaverick3Ornaments
    self._GridOrnament = require("XUi/XUiMaverick3/Grid/XUiGridMaverick3Ornaments").New(self.GridOrnaments2, self)
    ---@type XUiGridMaverick3Slay
    self._GridSlay = require("XUi/XUiMaverick3/Grid/XUiGridMaverick3Slay").New(self.GridSlay2, self)

    self.BtnConsume:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XEnumConst.Maverick3.Currency.Cultivate))
end

function XUiMaverick3Handbook:OnEnable()
    self._OrnamentsIndex = nil
    self._SlayIndex = nil
    
    local talentConfigs = self._Control:GetTalentConfigs()
    for _, cfg in pairs(talentConfigs) do
        if cfg.Type == XEnumConst.Maverick3.Plugin.Ornaments then
            table.insert(self._OrnamentsDatas, cfg)
        elseif cfg.Type == XEnumConst.Maverick3.Plugin.Slay then
            table.insert(self._SlayDatas, cfg)
        end
    end

    self:UpdateView()

    local btns = {}
    for _, grid in ipairs(self._OrnamentsGrids) do
        table.insert(btns, grid.Btn)
    end
    self.GroupOrnaments:Init(btns, handler(self, self.OnSelectOrnaments))

    btns = {}
    for _, grid in ipairs(self._SlayGrids) do
        table.insert(btns, grid.Btn)
    end
    self.GroupSlay:Init(btns, handler(self, self.OnSelectSlay))

    if self._OrnamentsIndex then
        self.GroupOrnaments:SelectIndex(self._OrnamentsIndex)
    elseif self._SlayIndex then
        self.GroupSlay:SelectIndex(self._SlayIndex)
    else
        self.GroupOrnaments:SelectIndex(1)
    end
    self.GridOrnaments.gameObject:SetActiveEx(false)
    self.GridSlay.gameObject:SetActiveEx(false)
end

function XUiMaverick3Handbook:OnDestroy()

end

function XUiMaverick3Handbook:UpdateView(isPlayTween)
    table.sort(self._OrnamentsDatas, self.Sort)
    table.sort(self._SlayDatas, self.Sort)

    local num1, num2 = 0, 0

    for i = 1, #self._OrnamentsDatas do
        local cfg = self._OrnamentsDatas[i]
        ---@type XUiGridMaverick3Ornaments
        local grid = self._OrnamentsGrids[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridOrnaments, self.GridOrnaments.parent)
            grid = require("XUi/XUiMaverick3/Grid/XUiGridMaverick3Ornaments").New(go, self)
            self._OrnamentsGrids[i] = grid
        end
        grid:SetData(cfg.Id)
        grid:Update(self._CharacterIndex, isPlayTween, self._CurId)
        if grid:IsOwned() then
            num1 = num1 + 1
        end
        if cfg.Id == self._DefaultSelectId then
            self._OrnamentsIndex = i
        end
    end

    for i = 1, #self._SlayDatas do
        local cfg = self._SlayDatas[i]
        ---@type XUiGridMaverick3Slay
        local grid = self._SlayGrids[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridSlay, self.GridSlay.parent)
            grid = require("XUi/XUiMaverick3/Grid/XUiGridMaverick3Slay").New(go, self)
            self._SlayGrids[i] = grid
        end
        grid:SetData(cfg.Id)
        grid:Update(self._CharacterIndex, isPlayTween, self._CurId)
        if grid:IsOwned() then
            num2 = num2 + 1
        end
        if cfg.Id == self._DefaultSelectId then
            self._SlayIndex = i
        end
    end

    self.TxtOrnamentsProgress1.text = num1
    self.TxtOrnamentsProgress2.text = string.format("/%s", #self._OrnamentsDatas)
    self.TxtSlayProgress1.text = num2
    self.TxtSlayProgress2.text = string.format("/%s", #self._SlayDatas)
end

function XUiMaverick3Handbook:OnSelectOrnaments(i)
    if XTool.IsNumberValid(self._CurId) then
        self:PlayAnimation("QieHuan")
    end
    local cfg = self._OrnamentsDatas[i]
    self._CurId = cfg.Id
    self._GridOrnament:Open()
    self._GridOrnament:SetData(cfg.Id)
    self._GridSlay:Close()
    self.TxtName.text = cfg.Name
    self.TxtDesc.text = cfg.Desc
    self:UpdateTalentButton()
    self.GroupSlay:CancelSelect()
end

function XUiMaverick3Handbook:OnSelectSlay(i)
    if XTool.IsNumberValid(self._CurId) then
        self:PlayAnimation("QieHuan")
    end
    local cfg = self._SlayDatas[i]
    self._CurId = cfg.Id
    self._GridOrnament:Close()
    self._GridSlay:Open()
    self._GridSlay:SetData(cfg.Id)
    self.TxtName.text = cfg.Name
    self.TxtDesc.text = cfg.Desc
    self:UpdateTalentButton()
    self.GroupOrnaments:CancelSelect()
end

function XUiMaverick3Handbook:UpdateTalentButton()
    local cfg = self._Control:GetTalentById(self._CurId)
    local isOwned = self._Control:IsTalentUnlock(cfg.Id)
    local isCond, desc = true, nil
    if XTool.IsNumberValid(cfg.Condition) then
        isCond, desc = XConditionManager.CheckCondition(cfg.Condition)
    end
    if not isCond then
        -- 未解锁
        self.BtnConsume.gameObject:SetActiveEx(false)
        self.BtnUnlock.gameObject:SetActiveEx(false)
        self.BtnEquip.gameObject:SetActiveEx(false)
        self.TxtLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = desc
    elseif not isOwned then
        -- 未拥有
        local itemCount = XDataCenter.ItemManager.GetCount(XEnumConst.Maverick3.Currency.Cultivate)
        local isCanBuy = itemCount >= cfg.NeedItemCount
        self.BtnConsume.gameObject:SetActiveEx(true)
        self.BtnConsume:SetButtonState(isCanBuy and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
        self.BtnConsume:SetNameByGroup(0, cfg.NeedItemCount)
        self.BtnConsume:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XEnumConst.Maverick3.Currency.Cultivate))
        self.BtnUnlock.gameObject:SetActiveEx(true)
        self.BtnUnlock:SetButtonState(isCanBuy and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
        self.BtnEquip.gameObject:SetActiveEx(false)
        self.TxtLock.gameObject:SetActiveEx(false)
    else
        local selectId
        if cfg.Type == XEnumConst.Maverick3.Plugin.Ornaments then
            selectId = self._Control:GetSelectOrnamentsId(self._CharacterIndex)
        else
            selectId = self._Control:GetSelectSlayId(self._CharacterIndex)
        end
        self.BtnEquip.gameObject:SetActiveEx(true)
        self.BtnEquip:SetButtonState(selectId ~= cfg.Id and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
        self.BtnConsume.gameObject:SetActiveEx(false)
        self.BtnUnlock.gameObject:SetActiveEx(false)
        self.TxtLock.gameObject:SetActiveEx(false)
    end
end

---@param a XTableMaverick3Talent
---@param b XTableMaverick3Talent
function XUiMaverick3Handbook.Sort(a, b)
    local isAUnlock = XMVCA.XMaverick3:IsTalentUnlock(a.Id)
    local isBUnlock = XMVCA.XMaverick3:IsTalentUnlock(b.Id)
    if isAUnlock ~= isBUnlock then
        return isAUnlock
    end
    return a.Id < b.Id
end

function XUiMaverick3Handbook:ReselectTalent()
    for i = 1, #self._OrnamentsDatas do
        if self._OrnamentsDatas[i].Id == self._CurId then
            self.GroupOrnaments:SelectIndex(i)
            return
        end
    end
    for i = 1, #self._SlayDatas do
        if self._SlayDatas[i].Id == self._CurId then
            self.GroupSlay:SelectIndex(i)
            return
        end
    end
end

function XUiMaverick3Handbook:OnBtnUnlockClick()
    if self.BtnUnlock.ButtonState == CS.UiButtonState.Disable then
        XUiManager.TipError(XUiHelper.GetText("Maverick3UnlockTalentTip"))
        return
    end
    self._Control:RequestMaverick3UnlockTalent(self._CurId, function()
        self:UpdateView(true)
        self:UpdateTalentButton()
        self:ReselectTalent()
    end)
end

function XUiMaverick3Handbook:OnBtnEquipClick()
    local cfg = self._Control:GetTalentById(self._CurId)
    if cfg.Type == XEnumConst.Maverick3.Plugin.Ornaments then
        if self._CurId == self._Control:GetSelectOrnamentsId(self._CharacterIndex) then
            XUiManager.TipError(XUiHelper.GetText("Maverick3OrnamentsHasEquipped"))
            return
        end
        self._Control:SaveSelectOrnamentsId(self._CharacterIndex, self._CurId)
    elseif cfg.Type == XEnumConst.Maverick3.Plugin.Slay then
        if self._CurId == self._Control:GetSelectSlayId(self._CharacterIndex) then
            XUiManager.TipError(XUiHelper.GetText("Maverick3SlayHasEquipped"))
            return
        end
        self._Control:SaveSelectSlayId(self._CharacterIndex, self._CurId)
    end
    XUiManager.TipError(XUiHelper.GetText("Maverick3EquipSuccess"))
    self:UpdateView()
    self:UpdateTalentButton()
end

return XUiMaverick3Handbook