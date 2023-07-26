local XUiGridSelectTactics = require("XUi/XUiEscape/Tactics/XUiGridSelectTactics")
local XUiPanelTactics = require("XUi/XUiEscape/Tactics/XUiPanelTactics")
--大逃杀玩法策略
local XUiEscape2Tactics = XLuaUiManager.Register(XLuaUi, "UiEscape2Tactics")

function XUiEscape2Tactics:OnAwake()
    self:AddBtnClickListener()
end

function XUiEscape2Tactics:OnStart(chapterId, layerId, tacticsNodeId)
    self._ChapterId = chapterId
    self._LayerId = layerId
    self._TacticsNodeId = tacticsNodeId
    self._EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self:InitHoldTactics()
    self:InitSelectTactics()
end

function XUiEscape2Tactics:OnEnable()
    self:Refresh()
end

function XUiEscape2Tactics:OnDisable()
end

--region UiRefresh
function XUiEscape2Tactics:Refresh()
    self:UpdateText()
    self:UpdateHoldTactics()
    self:UpdateSelectTactics()
end

function XUiEscape2Tactics:UpdateLock()
end

function XUiEscape2Tactics:UpdateText()
    self.TxtTitle.text = XEscapeConfigs.GetTacticsNodeName(self._TacticsNodeId)
    self.TxtTactics.text = XEscapeConfigs.GetTacticsNodeDesc(self._TacticsNodeId)
end
--endregion

--region Tactics
function XUiEscape2Tactics:InitHoldTactics()
    ---@type XUiPanelTactics
    self._PanelTactics = XUiPanelTactics.New(self.PanelHold)
end

function XUiEscape2Tactics:UpdateHoldTactics()
    self._PanelTactics:Refresh()
end

function XUiEscape2Tactics:InitSelectTactics()
    ---@type XUiGridSelectTactics[]
    self._GridSelectTactics = {}
    self.GirdTactics.gameObject:SetActiveEx(false)
end

function XUiEscape2Tactics:UpdateSelectTactics()
    local beSelectTactics = self._EscapeData:GetTacticsNodeTacticsList(self._TacticsNodeId)
    self:_UpdateSelectTactics(beSelectTactics)
    self:_UpdateSelectTacticsShow(not beSelectTactics and 1 or #beSelectTactics + 1)
end

---@param beSelectTactics XEscapeTactics[]
function XUiEscape2Tactics:_UpdateSelectTactics(beSelectTactics)
    if not beSelectTactics then
        return
    end
    for i, tactics in ipairs(beSelectTactics) do
        if not self._GridSelectTactics[i] then
            self._GridSelectTactics[i] = XUiGridSelectTactics.New(XUiHelper.Instantiate(self.GirdTactics.gameObject, self.PanelList.transform), self)
        end
        self._GridSelectTactics[i]:Refresh(tactics, self._LayerId, self._TacticsNodeId)
        self._GridSelectTactics[i]:SetActive(true)
    end
end

function XUiEscape2Tactics:_UpdateSelectTacticsShow(count)
    for i = count, #self._GridSelectTactics do
        self._GridSelectTactics[i]:SetActive(false)
    end
end
--endregion

--region BtnListener
function XUiEscape2Tactics:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.Close)
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
end

function XUiEscape2Tactics:OnBtnSkipClick()
    local isNodeClear = self._EscapeData:IsCurChapterTacticsNodeClear()
    if isNodeClear then
        XUiManager.TipErrorWithKey("EscapeCurLayerClear")
        return
    end

    local title = XUiHelper.GetText("EscapeTacticsSkipTitle")
    local content = XUiHelper.GetText("EscapeTacticsSkipContent")
    XUiManager.DialogTip(
            title,
            content,
            XUiManager.DialogType.Normal,
            nil,
            function()
                XDataCenter.EscapeManager.RequestEscapeSelectTactics(self._LayerId, self._TacticsNodeId, -1, function()
                    self:Close()
                end)
            end
    )
end
--endregion