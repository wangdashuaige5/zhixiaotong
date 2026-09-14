package com.neusoft.make.service.impl;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.neusoft.make.dto.PageDto;
import com.neusoft.make.mapper.UserMapper;
import com.neusoft.make.po.User;
import com.neusoft.make.service.IUserService;

/**
 * @Description: 用户Service接口实现类
 *
 * @author: 高军
 *
 * @date: 2026-9-7
 */
@Service
public class UserServiceImpl implements IUserService {

    @Autowired // DI 依赖注入注解
    UserMapper userMapper;

    /**
     * @Description: 分页查询用户(单表)
     * @param: keywords 查询条件关键字
     * @param: pageNum 当前页数
     * @param: maxPageNum 每页最多显示的记录数
     * @return: dto对象
     * @exception: 无
     */
    @Override
    public PageDto listUser(String keywords, int pageNum, int maxPageNum) {
        int totalRow = 0; // 初始化总行数
        int totalPageNum = 0; // 初始化总页数
        int preNum = 0; // 初始化上一页
        int nextNum = 0; // 初始化下一页
        int beginNum = 0; // 初始化开始记录数

        PageDto pageDto = new PageDto();
        // 获取总行数
        totalRow = userMapper.getUserCount(keywords);
        // 如果查询行数为0，那么直接结束。
        if (totalRow == 0) {
            return pageDto;
        }
        // 计算总页数
        if (totalRow % maxPageNum == 0) {
            totalPageNum = totalRow / maxPageNum;
        } else {
            totalPageNum = totalRow / maxPageNum + 1;
        }
        // 当前页数验证
        if (pageNum <= 0) {
            pageNum = 1;
        }
        if (pageNum > totalPageNum) {
            pageNum = totalPageNum;
        }
        // 设置上一页和下一页
        preNum = pageNum;
        nextNum = pageNum;
        if (pageNum > 1) {
            preNum--;
        }
        if (pageNum < totalPageNum) {
            nextNum++;
        }
        // 计算开始查询记录数
        beginNum = (pageNum - 1) * maxPageNum;
        // 开始查询业务数据
        List<User> list = userMapper.listUser(keywords, beginNum, maxPageNum);
        // 封装返回数据
        pageDto.setTotalRow(totalRow);
        pageDto.setTotalPageNum(totalPageNum);
        pageDto.setPreNum(preNum);
        pageDto.setNextNum(nextNum);
        pageDto.setPageNum(pageNum);
        pageDto.setMaxPageNum(maxPageNum);
        pageDto.setBeginNum(beginNum);
        pageDto.setList(list);
        return pageDto;
    }

    /**
     * @Description: 分页查询用户(多表)
     * @param: keywords 查询条件关键字
     * @param: pageNum 当前页数
     * @param: maxPageNum 每页最多显示的记录数
     * @return: dto对象
     * @exception: 无
     */
    @Override
    public PageDto listUser2(String keywords, int pageNum, int maxPageNum) {
        int totalRow = 0; // 初始化总行数
        int totalPageNum = 0; // 初始化总页数
        int preNum = 0; // 初始化上一页
        int nextNum = 0; // 初始化下一页
        int beginNum = 0; // 初始化开始记录数

        PageDto pageDto = new PageDto();
        // 获取总行数
        totalRow = userMapper.getUserCount2(keywords);
        // 如果查询行数为0，那么直接结束。
        if (totalRow == 0) {
            return pageDto;
        }
        // 计算总页数
        if (totalRow % maxPageNum == 0) {
            totalPageNum = totalRow / maxPageNum;
        } else {
            totalPageNum = totalRow / maxPageNum + 1;
        }
        // 当前页数验证
        if (pageNum <= 0) {
            pageNum = 1;
        }
        if (pageNum > totalPageNum) {
            pageNum = totalPageNum;
        }
        // 设置上一页和下一页
        preNum = pageNum;
        nextNum = pageNum;
        if (pageNum > 1) {
            preNum--;
        }
        if (pageNum < totalPageNum) {
            nextNum++;
        }
        // 计算开始查询记录数
        beginNum = (pageNum - 1) * maxPageNum;
        // 开始查询业务数据
        List<Map<String, Object>> list = userMapper.listUser2(keywords, beginNum, maxPageNum);
        // 封装返回数据
        pageDto.setTotalRow(totalRow);
        pageDto.setTotalPageNum(totalPageNum);
        pageDto.setPreNum(preNum);
        pageDto.setNextNum(nextNum);
        pageDto.setPageNum(pageNum);
        pageDto.setMaxPageNum(maxPageNum);
        pageDto.setBeginNum(beginNum);
        pageDto.setList(list);
        return pageDto;
    }

    /**
     * @Description: 用户添加
     * @param: user 包含用户信息的Map对象
     * @return: 整数 1==添加成功 0==添加失败
     * @exception: 无
     */
    @Override
    public int addUser(Map<String, Object> user) {
        return userMapper.addUser(user);
    }

    /**
     * @Description: 用户更新
     * @param: user 包含用户信息的Map对象
     * @return: 整数 1==更新成功 0==更新失败
     * @exception: 无
     */
    @Override
    public int updateUserById(Map<String, Object> user) {
        return userMapper.updateUserById(user);
    }

    /**
     * @Description: 用户删除
     * @param: user_id 包含用户编号信息的字符串对象
     * @return: 整数 1==删除成功 0==删除失败
     * @exception: 无
     */
    @Override
    public int deleteUserByIds(String user_id) {
        String[] split = user_id.split(","); // 3,6,10
        int n = 0;
        for (String str : split) {
            n = userMapper.deleteUserByIds(str);
        }
        return n;
    }
}