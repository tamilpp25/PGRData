--==============
--战斗准备界面敌方面板
--==============
local XUiSSBReadyEnemyGrid = XClass(nil, "XUiSSBReadyEnemyGrid")

function XUiSSBReadyEnemyGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanels()
end

function XUiSSBReadyEnemyGrid:InitPanels()
    self.Character = {}
    self.PanelCharecterNext.gameObject:SetActiveEx(false)
    XTool.InitUiObjectByUi(self.Character, self.PanelCharecter)
    local buffScript = require("XUi/XUiSuperSmashBros/Common/XUiSSBPanelMonsterBuffs")
    self.Buff = buffScript.New(self.Character.PanelBuff)
end

function XUiSSBReadyEnemyGrid:Refresh(data)
    self.Monster = data
    self:RefreshCharacter()
end

function XUiSSBReadyEnemyGrid:RefreshCharacter()
    self.Character.TxtAbility.text = XUiHelper.GetText("SSBBattleAbility", self.Monster:GetAbility())
    self.Character.RImgRole:SetRawImage(self.Monster:GetIcon())
    self.Character.ImgProgressHp.fillAmount = self.Monster:GetHpLeft() / 100
    self.Buff:SetBuff(self.Monster:GetBuffList())
end

function XUiSSBReadyEnemyGrid:SetOrder(order)
    self.Character.TxtPlayOrder.text = "P" .. order
end

function XUiSSBReadyEnemyGrid:SetReady(value)
    self.PanelReady.gameObject:SetActiveEx(value)
end

function XUiSSBReadyEnemyGrid:SetOut(value)
    if value then
        self.PlayOut = true
    end
end

function XUiSSBReadyEnemyGrid:SetWin(value)
    if value then
        self.PlayWin = true
    end
end

function XUiSSBReadyEnemyGrid:SetBan()
    self.PanelCharecter.gameObject:SetActiveEx(false)
    self.PanelReady.gameObject:SetActiveEx(false)
    self.PanelOut.gameObject:SetActiveEx(false)
    self.PanelWin.gameObject:SetActiveEx(false)
    self.PanelBan.gameObject:SetActiveEx(true)
end

function XUiSSBReadyEnemyGrid:SetNextEnemy(monsterGroup)
    if not monsterGroup then
        self.PanelCharecterNext.gameObject:SetActiveEx(false)
        return
    end
    self.PanelCharecterNext.gameObject:SetActiveEx(true)
    self.RImgRoleNext:SetRawImage(monsterGroup:GetIcon())
end

function XUiSSBReadyEnemyGrid:ShowPanel()
    --显示前先把相关动画初始化
    --这里不隐藏淘汰Panel是因为那个需要Hold状态，已经淘汰了还需要显示
    if XTool.UObjIsNil(self.GameObject) then return end
    self.GridPickEnemyWin:Stop()
    --self.PanelCharecterNextEnable:Stop()
    self.GridPickEnemyAlpha:Stop()
    self.PanelWin.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(true)
end

function XUiSSBReadyEnemyGrid:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiSSBReadyEnemyGrid:PlayAnimation()
    if XTool.UObjIsNil(self.GameObject) then return end
    if self.PlayOut then
        self.GridPickEnemyOut:Play() --淘汰动画
        self.PlayOut = nil
        return
    end
    if self.PlayWin then
        self.GridPickEnemyWin:Play() --胜利动画
        self.PlayWin = nil
        return
    end
    self.GridPickEnemyEnable:Play()
end

function XUiSSBReadyEnemyGrid:ResetPanelCharacterAlpha()
    if self.PanelCharecterCanvas then
        self.PanelCharecterCanvas.alpha = 1
    end 
end

function XUiSSBReadyEnemyGrid:PlaySwitchAnima(cb)
    self.OnSwitchFinishCb = cb
    self.GridPickEnemyEnable:Stop()
    self.PanelCharecterNextEnable:Play()
    XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.GameObject) then return end
                self:OnSwitchFinished()
            end, self.PanelCharecterNextEnable.duration * 1000)
end

function XUiSSBReadyEnemyGrid:OnSwitchFinished()
    if self.OnSwitchFinishCb then
        local cb = self.OnSwitchFinishCb
        self.OnSwitchFinishCb = nil
        cb()
        self:ResetPanelCharacterAlpha()
        self.GridPickEnemyOut:Stop()
        self.PanelOut.gameObject:SetActiveEx(false)
    end
end

function XUiSSBReadyEnemyGrid:PlayDisableAnimation()
    self.GridPickEnemyAlpha:Play()
end

function XUiSSBReadyEnemyGrid:HidePanelHp()
    local panelHp = self.Transform:FindTransform("PanelHP")
    if panelHp then panelHp.gameObject:SetActiveEx(false) end
end

return XUiSSBReadyEnemyGrid