--================
--超限乱斗怪兽详情页面
--================
local XUiSuperSmashBrosMonster = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosMonster")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiSuperSmashBrosMonster:OnStart(monsterList)
    self.DataList = monsterList
    self:InitPanels()
    self:SetActivityTimeLimit() --设置活动关闭时处理
end

function XUiSuperSmashBrosMonster:InitPanels()
    self:InitModel()
    self:InitPanelDetail()
    self:InitDTableMonsters()
    self:InitBtns()
    self.MonstersList:Refresh(self.DataList)
end
--================
--初始化角色模型和场景相机
--================
function XUiSuperSmashBrosMonster:InitModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.ImgEffectLogoGouzao = root:FindTransform("ImgEffectLogoGouzao")
    self.ImgEffectLogoGanran = root:FindTransform("ImgEffectLogoGanran")
    self.CameraFar = {
        root:FindTransform("UiCamFarLv"),
        root:FindTransform("UiCamFarGrade"),
        root:FindTransform("UiCamFarQuality"),
        root:FindTransform("UiCamFarSkill"),
        root:FindTransform("UiCamFarrExchange"),
    }
    self.CameraNear = {
        root:FindTransform("UiCamNearLv"),
        root:FindTransform("UiCamNearGrade"),
        root:FindTransform("UiCamNearQuality"),
        root:FindTransform("UiCamNearSkill"),
        root:FindTransform("UiCamNearrExchange"),
    }
    self.MonsterModel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end
--================
--初始化怪物详细面板
--================
function XUiSuperSmashBrosMonster:InitPanelDetail()
    local script = require("XUi/XUiSuperSmashBros/Monster/Panels/XUiSSBMonsterPanelDetail")
    self.DetailPanel = script.New(self)
end
--================
--初始化怪物组列表
--================
function XUiSuperSmashBrosMonster:InitDTableMonsters()
    local script = require("XUi/XUiSuperSmashBros/Monster/DTable/XUiSSBMonsterMonstersList")
    self.MonstersList = script.New(self)
end
--================
--选择怪物
--@param
--monsterData : XSuperSmashBrosMonster怪兽数据
--================
function XUiSuperSmashBrosMonster:SelectMonster(monster)
    self.Monster = monster
    self.DetailPanel:Refresh(self.Monster)
    self:UpdateModel()
end
--================
--刷新模型
--================
function XUiSuperSmashBrosMonster:UpdateModel()
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    local cb = function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        self:LoadModelCallBack(model)
    end
    self.MonsterModel:UpdateBossModel(self.Monster:GetMainMonsterModelName(), nil, nil, function(model) self:LoadModelCallBack(model) end, true)
end
--================
--读取模型后回调
--================
function XUiSuperSmashBrosMonster:LoadModelCallBack(model)
    local scale = self.Monster and self.Monster:GetMainMonsterModelScale()
    model.transform.localScale = CS.UnityEngine.Vector3(scale, scale, scale)
end

function XUiSuperSmashBrosMonster:InitBtns()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
end

function XUiSuperSmashBrosMonster:OnClickBtnBack()
    self:Close()
end

--==============
--设置活动关闭时处理
--==============
function XUiSuperSmashBrosMonster:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperSmashBrosManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.SuperSmashBrosManager.OnActivityEndHandler()
        end
    end)
end