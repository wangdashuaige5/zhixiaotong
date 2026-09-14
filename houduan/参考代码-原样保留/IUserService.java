package com.neusoft.make.service;

import java.util.Map;

import com.neusoft.make.dto.PageDto;

/**
 * @Description: 用户Service接口
 *
 * @author: 高军
 *
 * @date: 2026-9-7
 */
public interface IUserService {
    /**
     * @Description: 分页查询用户(单表)
     * @param: keywords 查询条件关键字
     * @param: pageNum 当前页数
     * @param: maxPageNum 每页最多显示的记录数
     * @return: dto对象
     * @exception: 无
     */
    public PageDto listUser(String keywords, int pageNum, int maxPageNum);

    /**
     * @Description: 分页查询用户(多表)
     * @param: keywords 查询条件关键字
     * @param: pageNum 当前页数
     * @param: maxPageNum 每页最多显示的记录数
     * @return: dto对象
     * @exception: 无
     */
    public PageDto listUser2(String keywords, int pageNum, int maxPageNum);

    /**
     * @Description: 用户添加
     * @param: user 包含用户信息的Map对象
     * @return: 整数 1==添加成功 0==添加失败
     * @exception: 无
     */
    int addUser(Map<String, Object> user);

    /**
     * @Description: 用户更新
     * @param: user 包含用户信息的Map对象
     * @return: 整数 1==更新成功 0==更新失败
     * @exception: 无
     */
    public int updateUserById(Map<String, Object> user);

    /**
     * @Description: 用户删除
     * @param: user_id 包含用户编号信息的字符串对象
     * @return: 整数 1==删除成功 0==删除失败
     * @exception: 无
     */
    public int deleteUserByIds(String user_id);

}