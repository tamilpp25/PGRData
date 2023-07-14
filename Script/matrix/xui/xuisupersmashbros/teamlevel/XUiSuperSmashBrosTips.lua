--==============
--超限乱斗队伍等级弹窗界面
--==============
local XUiSuperSmashBrosTips = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosTips")

function XUiSuperSmashBrosTips:OnStart()
    self:InitBaseBtns() --注册基础按钮
    self:InitPanels() --初始化各子面板
    self:SetActivityTimeLimit() --设置活动关闭时处理
end
--==============
--注册基础按钮
--==============
function XUiSuperSmashBrosTips:InitBaseBtns()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.OnClickBtnBack)
end
--==============
--返回按钮
--==============
function XUiSuperSmashBrosTips:OnClickBtnBack()
    self:Close()
end

function XUiSuperSmashBrosTips:OnStart()
    self:InitBaseBtns() --注册基础按钮
end

function XUiSuperSmashBrosTips:OnEnable()
    self:RefreshData()
end

function XUiSuperSmashBrosTips:RefreshData()
    local isMaxLevel = XDataCenter.SuperSmashBrosManager.GetIsTeamLvMax()

    local teamLv = XDataCenter.SuperSmashBrosManager.GetTeamLevel()
    local teamItemNum = XDataCenter.SuperSmashBrosManager.GetTeamItem()
    local teamLevelConfig = XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.TeamLevel)
    local nextLv = isMaxLevel and #teamLevelConfig or teamLv + 1 -- 防止读取下一个等级的数据越界

    local progressText = isMaxLevel and CSXTextManagerGetText("SuperSmashTeamLevelMax") or teamItemNum .."/" .. teamLevelConfig[nextLv].NeedItem
    local progressFillAmount = isMaxLevel and 1 or teamItemNum / teamLevelConfig[nextLv].NeedItem

    local nowLvConfig = teamLevelConfig[teamLv]
    local nextLvConfig = teamLevelConfig[nextLv]

    self.PanelTxtNext.gameObject:SetActive(not isMaxLevel) --满级使用满级面板
    self.PanelTxtNow.gameObject:SetActive(not isMaxLevel) 
    self.PanelTxtMax.gameObject:SetActive(isMaxLevel)

    -- 等级 ,进度条
    self.TxtLv.text = CSXTextManagerGetText("SuperSmashTeamLV", teamLv) 
    self.ImgProgress.fillAmount = progressFillAmount
    self.TxtLvProgress.text = progressText

    -- 属性
    if isMaxLevel then --满级使用满级面板
        self.TxtAtkMax.text = "+"..nowLvConfig.AtkUp
        self.TxtHpMax.text = "+".. math.modf(nowLvConfig.HpUp / 100) .. "%" -- HpUp这个属性已经从加生命改为 伤害减免，但是字段命名还没改
        self.TxtAbilityMax.text = "+"..nowLvConfig.AbilityUp
        return
    end

    self.TxtAtkNow.text = "+"..nowLvConfig.AtkUp
    self.TxtHpNow.text = "+".. math.modf(nowLvConfig.HpUp / 100) .. "%" -- HpUp这个属性已经从加生命改为 伤害减免，但是字段命名还没改
    self.TxtAbilityNow.text = "+"..nowLvConfig.AbilityUp

    self.TxtAtkNext.text = "+"..nextLvConfig.AtkUp
    self.TxtHpNext.text = "+".. math.modf(nextLvConfig.HpUp / 100) .. "%"
    self.TxtAbilityNext.text = "+"..nextLvConfig.AbilityUp
end
