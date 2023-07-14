--==============
--战斗准备界面我方角色列表项
--==============
local XUiSSBReadyOwnGrid = XClass(nil, "XUiSSBReadyOwnGrid")

function XUiSSBReadyOwnGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanels()
end

function XUiSSBReadyOwnGrid:InitPanels()
    self.Character = {}
    XTool.InitUiObjectByUi(self.Character, self.PanelCharecter)
    local colorScript = require("XUi/XUiSuperSmashBros/Common/XUiSSBPanelColor")
    self.Color = colorScript.New(self.Character.PanelColor)
    if self.BtnClick then self.BtnClick.CallBack = function() self:OnClick() end end
end

function XUiSSBReadyOwnGrid:Refresh(char)
    if char:GetEggRobotOrgId() ~= 0 and not char:GetIsEggOpen() then
        self.Chara = XDataCenter.SuperSmashBrosManager.GetRoleById(char:GetEggRobotOrgId()) -- 彩蛋原角色
        self.Chara:SetShowEggOrgCharEnable(true)
    else
        self.Chara = char --显示彩蛋机器人本体
        self.Chara:SetShowEggOrgCharEnable(false) 
    end
    self:RefreshCharacter()
end

function XUiSSBReadyOwnGrid:RefreshCharacter()
    self.PanelCharecter.gameObject:SetActiveEx(true)
    self.Character.TxtAbility.text = XUiHelper.GetText("SSBBattleAbility", self.Chara:GetAbility())
    self.Character.RImgRole:SetRawImage(self.Chara:GetSmallHeadIcon())
    local core = self.Chara:GetCore()
    self.Character.PanelCoreIn.gameObject:SetActiveEx(core ~= nil)
    self.Character.PanelCoreOut.gameObject:SetActiveEx(core == nil)
    if core then self.Character.RImgCoreIcon:SetRawImage(core:GetIcon()) end
    self.Character.ImgProgressHP.fillAmount = self.Chara:GetHpLeft() / 100
    self.Character.ImgProgressEn.fillAmount = self.Chara:GetSpLeft() / 100
end

function XUiSSBReadyOwnGrid:SetOrder(order)
    local mode = XDataCenter.SuperSmashBrosManager.GetPlayingMode()
    local colorIndex = XDataCenter.SuperSmashBrosManager.GetColorByIndexAndModeId(order, mode:GetId())
    self:SetColor(XSuperSmashBrosConfig.ColorTypeIndex[colorIndex])
    self.Character.TxtPlayOrder.text = "P" .. order
end

function XUiSSBReadyOwnGrid:SetColor(color)
    self.Color:ShowColor(color)
end

function XUiSSBReadyOwnGrid:SetReady(value)
    self.PanelReady.gameObject:SetActiveEx(value)
end

-- 揭开为彩蛋
function XUiSSBReadyOwnGrid:SetOpenEgg()
    self.OpenEgg = true
end

-- 设置为未知
function XUiSSBReadyOwnGrid:SetUnknown(flag)
    self.UnKonwn = flag -- 未知状态
    self.PanelUnknown.gameObject:SetActiveEx(flag) 
    self.PanelCharecter.gameObject:SetActiveEx(not flag)
end

function XUiSSBReadyOwnGrid:SetOut(value)
    if value then 
        self.PlayOut = true
    end
end

function XUiSSBReadyOwnGrid:SetWin(value)
    if value then
        self.PlayWin = true
    end
end

function XUiSSBReadyOwnGrid:SetBan()
    self.PanelCharecter.gameObject:SetActiveEx(false)
    self.PanelReady.gameObject:SetActiveEx(false)
    self.PanelOut.gameObject:SetActiveEx(false)
    self.PanelWin.gameObject:SetActiveEx(false)
    self.PanelBan.gameObject:SetActiveEx(true) 
end

function XUiSSBReadyOwnGrid:ShowPanel()
    --显示前先把相关动画初始化
    --这里不隐藏淘汰Panel是因为那个需要Hold状态，已经淘汰了还需要显示
    if XTool.UObjIsNil(self.GameObject) then return end
    self.GridPickOwnWin:Stop()
    self.PanelWin.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(true)
end

function XUiSSBReadyOwnGrid:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiSSBReadyOwnGrid:PlayAnimation()
    if XTool.UObjIsNil(self.GameObject) then return end
    if self.PlayOut then
        self.GridPickOwnOut:Play() --淘汰动画
        self.PlayOut = nil
        return
    end
    if self.PlayWin then
        self.GridPickOwnWin:Play() --胜利动画
        self.PlayWin = nil
        return
    end
    -- 彩蛋动画 (每次出现时播放一次，之后重开模式才会再播放 根据玩家id和角色id上锁，每次结束当前模式的对战时解锁) cxldV2
    local isPlayEggAnimEnable = self.Chara and XSaveTool.GetData(string.format("%d%dSuperSmashEggAnim", XPlayer.Id, self.Chara:GetId())) ~= 1 and self.Chara:GetIsEggOpen()
    if isPlayEggAnimEnable then
        self.EasterEgg.gameObject:SetActive(true)
        local eggConfig = self.Chara:GetEggConfig()
        -- 设置 台词、头像、彩蛋名
        self.EggTalk.text = eggConfig.Desc
        self.EggRImgHead:SetRawImage(eggConfig.RoleHead)
        self.EggName.text = eggConfig.Name
        -- 动画
        self.IsPlayingEgg = true -- 彩蛋播放期间不能操作
        XLuaUiManager.SetMask(true)
        self.EggAnimEnable = self.EasterEgg:Find("Animation/EasterEggEnable")
        self.EggAnimEnable:PlayTimelineAnimation()

        self.EggAnimDisable = self.EasterEgg:Find("Animation/EasterEggDisable")
        XScheduleManager.ScheduleOnce(function()
            self.EggAnimDisable:PlayTimelineAnimation(function ()
                self.IsPlayingEgg = false
                XLuaUiManager.SetMask(false)
            end)
        end, 1500)
        XSaveTool.SaveData(string.format("%d%dSuperSmashEggAnim", XPlayer.Id, self.Chara:GetId()), 1)
    end
    self.GridPickOwnEnable:Play()
end

function XUiSSBReadyOwnGrid:PlayDisableAnimation()
    self.GridPickOwnAlpha:Play()
end

function XUiSSBReadyOwnGrid:OnClick()
    local playingMode = XDataCenter.SuperSmashBrosManager.GetPlayingMode()
    XLuaUiManager.Open("UiSuperSmashBrosCharacter", playingMode:GetBattleTeam(), false)
end
    
return XUiSSBReadyOwnGrid