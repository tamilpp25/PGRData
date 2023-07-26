local XUiCharacterQualitySystemV2P6 = XLuaUiManager.Register(XLuaUi, "UiCharacterQualitySystemV2P6")

local PanelName = 
{
    XPanelQualityWholeV2P6 = "XPanelQualityWholeV2P6",  -- QualitySystem的主界面
    XPanelQualitySingleV2P6 = "XPanelQualitySingleV2P6", -- 二级进化球界面
    XPanelQualityUpgradeDetailV2P6 = "XPanelQualityUpgradeDetailV2P6", -- 进化升级详情弹窗界面
}

function XUiCharacterQualitySystemV2P6:OnAwake()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self.OpenChildStack = XStack.New()
    self.IsEvoPerform = nil --演出锁

    -- 初始化3d动态列表
    self.ParentUi.PanelModel:InitDynamicTable3D(self)

    self:InitPanel()
end

function XUiCharacterQualitySystemV2P6:InitPanel()
    self.PanelIndex = 
    {
        {Name = PanelName.XPanelQualityWholeV2P6, ParentTrans = "PanelQualityWhole", AssetPath = CS.XGame.ClientConfig:GetString("PanelQualityWholeV2P6")},
        {Name = PanelName.XPanelQualitySingleV2P6, ParentTrans = "PanelQualitySingle", AssetPath = CS.XGame.ClientConfig:GetString("PanelQualitySingleV2P6"), 
            Args = {function (afterEvoQuality)
                self:OnCharEvolution(afterEvoQuality)
            end}
        },
        {Name = PanelName.XPanelQualityUpgradeDetailV2P6, ParentTrans = "PanelQualityUpgradeDetail", AssetPath = CS.XGame.ClientConfig:GetString("PanelQualityUpgradeDetailV2P6"),
            Args = {function (nextQuality)
                self:OnUpgradeCloseCb(nextQuality)
            end}
        },
    }

    for k, panelInfo in pairs(self.PanelIndex) do
        local proxy = require("XUi/XUiCharacterV2P6/PanelChildUi/"..panelInfo.Name)
        local path = panelInfo.AssetPath
        local ui = self[panelInfo.ParentTrans]:LoadPrefab(path)
        ui.gameObject:SetActiveEx(false)

        local args = panelInfo.Args or {}
        self[panelInfo.Name] = proxy.New(ui, self, table.unpack(args))
    end

    -- 点击特效动态列表的回调
    self.ParentUi.PanelModel:SetDynamicTableClickCb(function (seleQuality)
        self:OnQualityBallSelected(seleQuality)
    end)
end

function XUiCharacterQualitySystemV2P6:OnStart()
    self:OpenChildPanel(PanelName.XPanelQualityWholeV2P6) 
end

function XUiCharacterQualitySystemV2P6:OnEnable()
    -- 进化界面更改资源栏为对应角色碎片
    local character = self.ParentUi.CurCharacter
    local fragmentItemId = XCharacterConfigs.GetCharacterItemId(character.Id)
    self.ParentUi:SetPanelAsset(XDataCenter.ItemManager.ItemId.FreeGem, fragmentItemId, XDataCenter.ItemManager.ItemId.Coin)
    self.ParentUi.PanelModel:SetCameraQualityActive(true)
end

-- 不是真的子ui，是panel
function XUiCharacterQualitySystemV2P6:OpenChildPanel(targetName)
    for k, name in pairs(PanelName) do
        if name == targetName then
            self[name]:Open()
        else
            self[name]:Close()
        end
    end

    local regisBackFun = function ()
        if self.OpenChildStack:Count() >= 2 then
            self.ParentUi:SetBackTrigger(function ()
                self:BackFun()
            end)
        else
            self.ParentUi:SetBackTrigger(nil)
        end
    end

    if self.OpenChildStack:Peek() == targetName then
        regisBackFun()
        return
    end
    self.OpenChildStack:Push(targetName)
    regisBackFun()
end

-- 该界面下所有的子界面想返回到上一个界面都要通过OpenLastChildUi打开，不能通过新开OpenChildPanel打开
function XUiCharacterQualitySystemV2P6:OpenLastChildUi()
    if not self.OpenChildStack or self.OpenChildStack:Count() < 2 then
        return
    end
    local curUiname = self.OpenChildStack:Peek()
    self.OpenChildStack:Pop()
    local targetUiName = self.OpenChildStack:Peek()

    -- 特殊处理(single回whole)
    if targetUiName == PanelName.XPanelQualityWholeV2P6 and curUiname == PanelName.XPanelQualitySingleV2P6 then
        self[curUiname]:Close() -- 提前关闭single
        CS.XUiManager.Instance:SetMask(true)
        self.ParentUi.PanelModel:PlayCharModelAnime("SingleToQuality", function ()
            self:OpenChildPanel(targetUiName)
            CS.XUiManager.Instance:SetMask(false)
        end)
        return
    end

    self:OpenChildPanel(targetUiName)
end

-- 回到qualitySystem的主界面（whole界面）
function XUiCharacterQualitySystemV2P6:BackToQualityHome()
    self.ParentUi:SetBackTrigger(nil)
    self.OpenChildStack:Clear()
    self:OpenChildPanel(PanelName.XPanelQualityWholeV2P6)
end

-- 在该界面下点击返回按钮使用的方法
function XUiCharacterQualitySystemV2P6:BackFun()
    -- 子界面关闭时，打开上一次打开的子界面
    if self.OpenChildStack and self.OpenChildStack:Count() >= 2 then
        self:OpenLastChildUi()    
    end
end

-- 单品质展示界面 返回时应该回到所有品质球展示界面
function XUiCharacterQualitySystemV2P6:OnQualityBallSelected(selectQuality)
    self.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.QualitySingle)
    self.ParentUi.PanelModel:PlayCharModelAnime("QualityToSingle") -- 移动镜头
    self.ParentUi.PanelModel:PlayCharModelAnime("PanelBigBallEnable") -- 刷新大球
    self:OpenChildPanel(PanelName.XPanelQualitySingleV2P6)
    self[PanelName.XPanelQualitySingleV2P6]:Refresh(selectQuality)
end

-- 升品质提示详情界面 返回应该回到单品质展示界面
function XUiCharacterQualitySystemV2P6:OnCharEvolution(afterEvoQuality)
    self.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.QualityUpgradeDetail)
    self:OpenChildPanel(PanelName.XPanelQualityUpgradeDetailV2P6)
    self[PanelName.XPanelQualityUpgradeDetailV2P6]:Refresh(afterEvoQuality)
    -- 打开升级详情界面时打开下一个大球
    self.ParentUi.PanelModel:SetPanelEffectBallBigActive(true)
    self.ParentUi.PanelModel:RefreshBigBallEffect(afterEvoQuality, nil, true)
    self.ParentUi.PanelModel:OpenBigEffectBall(afterEvoQuality)
end

-- 关闭详情界面 要直接返回到QualitySystem的主界面
function XUiCharacterQualitySystemV2P6:OnUpgradeCloseCb(nextQuality)
    self.IsEvoPerform = true -- 加上演出锁、禁止玩家操作、禁止其他地方操作动态列表
    CS.XUiManager.Instance:SetMask(true)

    self:BackToQualityHome()
    if nextQuality > XEnumConst.CHARACTER.MAX_QUALITY then
        return
    end

    -- 关闭大球展示
    self.ParentUi.PanelModel:SetPanelEffectBallBigActive(false)
    self.ParentUi.PanelModel:PlayCharModelAnime("UpgradeDetailToQuality")
    self.ParentUi.PanelModel:RefreshDynamicTable3DByEvoPerform(nextQuality, function ()
        self.IsEvoPerform = false
        CS.XUiManager.Instance:SetMask(false)
    end)
end

function XUiCharacterQualitySystemV2P6:OnDisable()
    self.IsEvoPerform = false
    self.ParentUi.PanelModel:SetCameraQualityActive(false)
end

return XUiCharacterQualitySystemV2P6
