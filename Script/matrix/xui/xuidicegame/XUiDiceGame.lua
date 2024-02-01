local XUiPanelStart = require("XUi/XUiDiceGame/XUiPanelStart")
local XUiPanelOperation = require("XUi/XUiDiceGame/XUiPanelOperation")
local XUiPanelEasterEgg = require("XUi/XUiDiceGame/XUiPanelEasterEgg")

---@class XUiDiceGame
---@field protected BtnBack XUiComponent.XUiButton
---@field protected BtnMainUi XUiComponent.XUiButton
---@field protected BtnHelp XUiComponent.XUiButton
---@field protected SubPanels table<number, XUiDiceGameSubPanel>
local XUiDiceGame = XLuaUiManager.Register(XLuaUi, "UiDiceGame")

function XUiDiceGame:OnStart()
	self:InitTopView()
	self:InitGamePanels()
	self.stage = 0
end

function XUiDiceGame:InitTopView()
	self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
	self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
	self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)

	--代币面板
	self.AssetPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset, self)
	local itemId = XDataCenter.DiceGameManager.GetCoinItemId()
	XDataCenter.ItemManager.AddCountUpdateListener({ itemId }, function(id, count)
		self.AssetPanel:Refresh({ itemId })
		self.OperationPanel:UpdateCoinCountColor(id, count)
	end, self.AssetPanel)
	self.AssetPanel:Refresh({ itemId })
end

function XUiDiceGame:InitGamePanels()
	--self:RemoveLocalDataForTest()

	self.StartPanel = XUiPanelStart.New(self.PanelStart, self)
	self.OperationPanel = XUiPanelOperation.New(self.PanelOperation, self)
	self.EasterEggPanel = XUiPanelEasterEgg.New(self.PanelTip)
	self.SubPanels = {}
	self.SubPanels[#self.SubPanels + 1] = self.StartPanel
	self.SubPanels[#self.SubPanels + 1] = self.OperationPanel
end

function XUiDiceGame:CreateTimeListener()
	if not self.Timer then
		self.Timer = XScheduleManager.ScheduleForever(function()
			self:AutoQuitOnFinish()
		end, XScheduleManager.SECOND , 0)
	end
end

function XUiDiceGame:OnEnable()
	self:CreateTimeListener()
	if XDataCenter.DiceGameManager.HasThrowResult() then
		self:UpdatePanel(2, false, 0)
	else
		self:UpdatePanel(1, false, 0)
	end

	local key = string.format("%s_DiceGame%d_FirstOpen", XPlayer.Id, XDataCenter.DiceGameManager.GetActivityId())
	if not XSaveTool.GetData(key) then
		self:OnBtnHelpClick()
		XSaveTool.SaveData(key, true)
	end
end

function XUiDiceGame:OnBtnBackClick()
	self:Close()
end

function XUiDiceGame:OnBtnMainUiClick()
	XLuaUiManager.RunMain()
end

function XUiDiceGame:OnBtnHelpClick()
	local helpId = tonumber(XDataCenter.DiceGameManager.GetActivityConfigValue("HelpId"))
	local helpDataKey = XHelpCourseConfig.GetHelpCourseTemplateById(helpId).Function or "DiceGameHelp"
	XUiManager.ShowHelpTip(helpDataKey)
end

function XUiDiceGame:PopupEasterEgg(egg)
	self.EasterEggPanel:Open(egg)
end

---@param animFlag int @二进制组合，1:PanelStart, 2:PanelOperation
function XUiDiceGame:UpdatePanel(stage, signal, animFlag)
	if stage <= 0 then
		XLog.Error("DiceGame.UpdatePanel: invalid ui stage:" .. stage)
		return
	end

	animFlag = animFlag or 0
	local function ShowNextPanel()
		self.SubPanels[stage]:SetActive(true, signal, (animFlag & (1 << (stage - 1))) ~= 0)
	end
	if self.stage > 0 then
		if self.stage == stage then
			ShowNextPanel()
		else
			if (animFlag & (1 << (self.stage - 1))) ~= 0 then
				self.SubPanels[self.stage]:SetActive(false, signal, true, function()
					ShowNextPanel()
				end)
			else
				self.SubPanels[self.stage]:SetActive(false, signal, false)
				ShowNextPanel()
			end
		end
	else
		self.SubPanels[stage]:SetActive(true, signal, (animFlag & (1 << (stage - 1))) ~= 0)
	end
	self.stage = stage
end

function XUiDiceGame:OnDisable()
	if self.Timer then
		XScheduleManager.UnSchedule(self.Timer)
	end
end

function XUiDiceGame:OnDestroy()
	self.OperationPanel:SaveDefaultSelectionData()
	self.EasterEggPanel:SaveLocalData()
	self.StartPanel:OnDestroy()
end

function XUiDiceGame:AutoQuitOnFinish()
	local timeLeft = XDataCenter.DiceGameManager.GetDiceGameTimeLeft()
	if timeLeft <= 0 then
		XUiManager.TipText("ActivityAlreadyOver")
		self:OnBtnMainUiClick()
	end
end

function XUiDiceGame.RemoveLocalDataForTest()
	if XDataCenter.DiceGameManager.GetScore() == 0 then
		XUiPanelOperation.RemoveDefaultSelectionData()
		XUiPanelEasterEgg.RemoveLocalData()
	end
end

---@class XUiDiceGameSubPanel
local XUiDiceGameSubPanel = {}
---@param active boolean
---@param signal boolean
---@param playAnim boolean
---@param disableFinishCb fun():void
function XUiDiceGameSubPanel:SetActive(active, signal, playAnim, disableFinishCb) end