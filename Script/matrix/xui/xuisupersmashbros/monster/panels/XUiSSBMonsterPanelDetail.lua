--================
--怪物页面怪物详细面板
--================
local XUiSSBMonsterPanelDetail = XClass(nil, "XUiSSBMonsterPanelDetail")

function XUiSSBMonsterPanelDetail:Ctor(panel)
    self.RootUi = panel
    XTool.InitUiObjectByUi(self, panel.PanelDetail)
    self:InitPanel()
end
--================
--初始化
--================
function XUiSSBMonsterPanelDetail:InitPanel()
    self:InitDynamicTables() --动态列表
    self:InitBtns() --按钮
end
--================
--初始化动态列表
--================
function XUiSSBMonsterPanelDetail:InitDynamicTables()
    local script_words = require("XUi/XUiSuperSmashBros/Monster/DTable/XUiSSBMonsterWordsList")
    local script_rewards = require("XUi/XUiSuperSmashBros/Monster/DTable/XUiSSBMonsterRewardList")
    local script_monsters = require("XUi/XUiSuperSmashBros/Monster/DTable/XUiSSBMonsterSubMonstersList")
    self.WordsList = script_words.New(self.RootUi, self.WordsList)
    self.SubMonstersList = script_monsters.New(self.RootUi, self.SubMonstersList)
    self.RewardList = script_rewards.New(self.RootUi, self.RewardsList)
end
--================
--初始化按钮
--================
function XUiSSBMonsterPanelDetail:InitBtns()
    self.BtnDetail.CallBack = function() self:OnClickBtnDetail() end
end
--================
--刷新怪物数据
--================
function XUiSSBMonsterPanelDetail:Refresh(monster)
    if not monster then return end
    self.Monster = monster
    self.WordsList:Refresh(self.Monster)
    self.SubMonstersList:Refresh(self.Monster)
    self.RewardList:Refresh(self.Monster)
    self.TxtName.text = self.Monster:GetName()
    self.TxtAbility.text = self.Monster:GetAbility()
    self.TxtPoint.text = self.Monster:GetPoint()
end
--================
--点击详细
--================
function XUiSSBMonsterPanelDetail:OnClickBtnDetail()
    local words = self.Monster:GetBuffList()
    if not (words and next(words)) then
        XUiManager.TipText("SSBMonsterNoWords")
        return
    end
    XLuaUiManager.Open("UiSuperSmashBrosWords", self.Monster:GetBuffList())
end

return XUiSSBMonsterPanelDetail