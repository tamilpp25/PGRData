--==============
--战斗准备界面我方角色列表项
--==============
local XUiSSBReadyOwnGrid = XClass(nil, "XUiSSBReadyOwnGrid")

function XUiSSBReadyOwnGrid:Ctor(uiPrefab)
    self._Timer = false
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanels()
end

function XUiSSBReadyOwnGrid:InitPanels()
    self.Character = {}
    XTool.InitUiObjectByUi(self.Character, self.PanelCharecter)
    local colorScript = require("XUi/XUiSuperSmashBros/Common/XUiSSBPanelColor")
    if self.Character.PanelColor then
        self.Color = colorScript.New(self.Character.PanelColor)
    end
    if self.BtnClick then self.BtnClick.CallBack = function() self:OnClick() end end
end

function XUiSSBReadyOwnGrid:Refresh(char, record, recordIndex)
    if char:GetEggRobotOrgId() ~= 0 and not char:GetIsEggOpen() then
        ---@type XSmashBCharacter
        self.Chara = XDataCenter.SuperSmashBrosManager.GetRoleById(char:GetEggRobotOrgId()) -- 彩蛋原角色
        self.Chara:SetShowEggOrgCharEnable(true)
    else
        self.Chara = char --显示彩蛋机器人本体
        self.Chara:SetShowEggOrgCharEnable(false) 
    end
    self:RefreshCharacter(nil, record, recordIndex)
end

---@param record XSmashBRecord
---@param recordIndex number
function XUiSSBReadyOwnGrid:RefreshCharacter(character, record, recordIndex)
    character = character or self.Chara
    self.PanelCharecter.gameObject:SetActiveEx(true)
    if record then
        local icon = record:GetCharacterIcon(recordIndex)
        if icon then
            self.Character.RImgRole:SetRawImage(icon)
        end
        self.Character.TxtAbility.text = XUiHelper.GetText("SSBBattleAbility", record:GetAbility())
    else
        self.Character.TxtAbility.text = XUiHelper.GetText("SSBBattleAbility", character:GetAbility())
        self.Character.RImgRole:SetRawImage(character:GetSmallHeadIcon())
    end
    local core = character:GetCore()
    if character:IsNoCareer() or record then
        self.Character.PanelCoreIn.gameObject:SetActiveEx(false)
        self.Character.PanelCoreOut.gameObject:SetActiveEx(false)
    else
        self.Character.PanelCoreIn.gameObject:SetActiveEx(core ~= nil)
        self.Character.PanelCoreOut.gameObject:SetActiveEx(core == nil)
    end
    if core then self.Character.RImgCoreIcon:SetRawImage(core:GetIcon()) end
    if record and recordIndex then
        self.Character.ImgProgressHP.fillAmount = record:GetCharacterHpLeft(recordIndex) / 100
    else
        self.Character.ImgProgressHP.fillAmount = character:GetHpLeft() / 100
    end
    if self.Character.ImgProgressEn then
        self.Character.ImgProgressEn.fillAmount = character:GetSpLeft() / 100
    end
    self:RefreshSkill()
end

function XUiSSBReadyOwnGrid:SetOrder(order)
    local mode = XDataCenter.SuperSmashBrosManager.GetPlayingMode()
    local colorIndex = XDataCenter.SuperSmashBrosManager.GetColorByIndexAndModeId(order, mode:GetId())
    self:SetColor(XSuperSmashBrosConfig.ColorTypeIndex[colorIndex])
    self.Character.TxtPlayOrder.text = "P" .. order
end

function XUiSSBReadyOwnGrid:SetAssistance()
    self:SetColor(XSuperSmashBrosConfig.PanelColorType.Purple)
    self.Character.TxtPlayOrder.text = XUiHelper.GetText("SuperSmashAssistance")
end

function XUiSSBReadyOwnGrid:SetColor(color)
    if self.Color then
        self.Color:ShowColor(color)
    end
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
    if self.PanelUnknown then
        self.PanelUnknown.gameObject:SetActiveEx(flag)
    end
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
    if self.PanelOut then
        self.PanelOut.gameObject:SetActiveEx(false)
    end
    if self.PanelWin then
        self.PanelWin.gameObject:SetActiveEx(false)
    end
    if self.PanelBan then
        self.PanelBan.gameObject:SetActiveEx(true)
    end
end

function XUiSSBReadyOwnGrid:ShowPanel()
    --显示前先把相关动画初始化
    --这里不隐藏淘汰Panel是因为那个需要Hold状态，已经淘汰了还需要显示
    if XTool.UObjIsNil(self.GameObject) then return end
    self.GridPickOwnWin:Stop()
    if self.PanelWin then
        self.PanelWin.gameObject:SetActiveEx(false)
    end
    self.GameObject:SetActiveEx(true)
end

function XUiSSBReadyOwnGrid:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiSSBReadyOwnGrid:PlayAnimation()
    if XTool.UObjIsNil(self.GameObject) then return end

    ---@type XSmashBMode
    local mode = XDataCenter.SuperSmashBrosManager.GetPlayingMode()
    local ownTeam = mode:GetBattleTeam()
    local battleIndex = mode:GetBattleCharaIndex()
    local isPlayEggVer3 = self.Chara and self.Chara:IsSmashEggRobot()
            and ownTeam[battleIndex] == self.Chara:GetId()
            and XDataCenter.SuperSmashBrosManager.IsJustFail()

    if not isPlayEggVer3 then
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
    end

    -- 彩蛋动画 (每次出现时播放一次，之后重开模式才会再播放 根据玩家id和角色id上锁，每次结束当前模式的对战时解锁) cxldV2
    local isPlayEggAnimEnable = self.Chara and XSaveTool.GetData(string.format("%d%dSuperSmashEggAnim", XPlayer.Id, self.Chara:GetId())) ~= 1 and self.Chara:GetIsEggOpen()
    if isPlayEggVer3 then
        isPlayEggAnimEnable = true
        self.PlayOut = nil
    end

    if isPlayEggAnimEnable then
        local eggConfig = self.Chara:GetEggConfig()
        -- 设置 台词、头像、彩蛋名
        self.EggTalk.text = eggConfig.Desc
        self.EggRImgHead:SetRawImage(eggConfig.RoleHead)
        self.EggName.text = eggConfig.Name
        -- 动画
        self.IsPlayingEgg = true -- 彩蛋播放期间不能操作
        XLuaUiManager.SetMask(true)

        local function playEgg()
            self.EasterEgg.gameObject:SetActive(true)
            self.GridPickOwnOut:Stop()
            if self.PanelOut then
                self.PanelOut.gameObject:SetActiveEx(false)
            end
            self.GridPickOwnWin:Play() --胜利动画
            self:RefreshCharacter()
            
            self.EggAnimEnable = self.EasterEgg:Find("Animation/EasterEggEnable")
            self.EggAnimEnable:PlayTimelineAnimation()

            self.EggAnimDisable = self.EasterEgg:Find("Animation/EasterEggDisable")
            self._Timer = XScheduleManager.ScheduleOnce(function()
                self.EggAnimDisable:PlayTimelineAnimation(function ()
                    self.IsPlayingEgg = false
                    XLuaUiManager.SetMask(false)
                end)
            end, 1500)
            XSaveTool.SaveData(string.format("%d%dSuperSmashEggAnim", XPlayer.Id, self.Chara:GetId()), 1)
        end

        if isPlayEggVer3 then
            -- 先播放淘汰动画 再切换角色
            local oldCharacterId = self.Chara:GetEggRobotOrgId()
            local oldCharacter = XDataCenter.SuperSmashBrosManager.GetRoleById(oldCharacterId)
            self:RefreshCharacter(oldCharacter)
            self.GridPickOwnOut:Play()
            self._Timer = XScheduleManager.ScheduleOnce(playEgg, 1500)
        else
            playEgg()
        end
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

function XUiSSBReadyOwnGrid:RefreshSkill()
    if not self.Character.TxtSkill then
        return
    end
    local skillName = self.Chara:GetAssistantSkillName()
    if skillName then
        self.Character.TxtSkill.text = skillName
    else
        self.Character.TxtSkill.text = ""
    end
end

function XUiSSBReadyOwnGrid:OnDestroy()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
        XLuaUiManager.SetMask(false)
    end
end

return XUiSSBReadyOwnGrid