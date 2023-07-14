-- 通用出战界面代理管理
XUiNewRoomSingleProxy = XUiNewRoomSingleProxy or {}

XUiNewRoomSingleProxy.ProxyDic = {}
--=================
-- 注册出战界面代理
--@param stageType:FubenManager中关卡的分类StageType
--@param proxy:代理
--=================
function XUiNewRoomSingleProxy.RegisterProxy(stageType, proxy)
    if XUiNewRoomSingleProxy.ProxyDic[stageType] then return end
    XUiNewRoomSingleProxy.ProxyDic[stageType] = proxy
end

return XUiNewRoomSingleProxy

--[[--============================================================
--                         页面代理方法
--============================================================
所有方法都可选择性使用，不写该方法会调用NewRoomSingle本身的默认方法
代理需使用上面的注册方法才能使用(一个FubenManager的StageType分类代理只有一个)
如有需要追加的方法请在下方补充

--================
--初始化界面 在出战界面OnStart初始化界面所有元素后调用
--================
function ProxyName:InitEditBattleUi(newRoomSingleUi)

--================
--点击出战界面资料时的显示处理
--@param val 显示资料状态，参照XUiNewRoomSingle.OnBtnShowInfoToggle方法
--================
function ProxyName:OnBtnShowInfoToggle(newRoomSingleUi, val)

--================
--刷新成员信息处理
--================
function ProxyName:InitEditBattleUiCharacterInfo(newRoomSingleUi)

--================
--保存玩法出战队伍操作，更改队长位和首发位时触发
--================
function ProxyName:SetEditBattleUiTeam(newRoomSingleUi)

--================
--刷新警告面板
--================
function ProxyName:UpdateFightControl(newRoomSingleUi. curTeam)

--================
--获取队长ID
--@return captainId:队长的ID
--================
function ProxyName:GetEditBattleUiCaptainId(newRoomSingleUi)

--================
--获取队伍数据
--@return teamData:队伍数据
--================
function ProxyName:GetBattleTeamData(newRoomSingleUi)

--================
--当点击角色模型时
--@param charPos:点击的角色的队伍位置
--================
function ProxyName:HandleCharClick(newRoomSingleUi, charPos)

--================
--当点击主界面按钮时
--================
function ProxyName:HandleBtnMainUiClick()


--================
--刷新队伍，编队角色或编队顺序发生变化时触发
--================
function ProxyName:UpdateTeam(newRoomSingleUi)

--================
--刷新模型
--@param charId:角色Id
--@param roleModelPanel:3D UI角色
--@param pos:角色位置
--================
function ProxyName:UpdateRoleModel(newRoomSingleUi, charId, roleModelPanel, pos)

--================
--返回正确的队员ID(基础角色使用CharacterId，机器人使用RobotId)
--@param teamIds:队员Id
--用于显示队员资料(如队长技能)
--================
function ProxyName:GetRealCharData(newRoomSingleUi)

--================
--接受到活动重置或结束消息时
--================
function ProxyName:OnResetEvent(newRoomSingleUi)

--================
--筛选角色
--================
function ProxyName:LimitCharacter(newRoomSingleUi, curTeam)

--================
--页面获取机器人Id数组
--================
function ProxyName:GetRobotIds(stageId)

--================
--页面检查角色是否能点击
--================
function ProxyName:CheckCanCharClick(newRoomSingleUi, stageId)

--================
--页面检查角色是否能长按拖拽
--================
function ProxyName:CheckCanCharLongClick(newRoomSingleUi, stageId)

--================
--页面检查是否隐藏切换第一次战斗位置按钮信息
--================
function ProxyName:GetIsHideSwitchFirstFightPosBtns()
    
--================
--关闭界面销毁时
--================
function ProxyName:DestroyNewRoomSingle()

--================
--更新伙伴信息
--@param newRoomSingleUi:页面对象
--@param maxCharaCount:编队角色最大值
--================
function ProxyName:UpdatePartnerInfo(newRoomSingleUi, maxCharaCount)
--================
--更新人物特性信息
--================
function ProxyName:UpdateFeatureInfo(newRoomSingleUi, maxCharaCount)
--================
--进战前检查
--================
function ProxyName:CheckEnterFight(newRoomSingleUi, CurTeam)
--================
--更新队伍后是否保存队伍数据
--================
function ProxyName:GetIsSaveTeamData(newRoomSingleUi, maxCharaCount)
    
--================
--处理切换队伍位置
--================
function ProxyName:SwitchTeamPos(stageId, fromPos, toPos)

--================
--设置左下红底的出战人数说明
--================
function ProxyName:SetPanelRogueLike(newRoomSingleUi)

--================
--设置关卡说明
--================
function ProxyName:SetRogueLikeCharacterTips(newRoomSingleUi)

--================
--设置界面提示
--================
function ProxyName:RefreshCharacterTypeTips(newRoomSingleUi)
]]