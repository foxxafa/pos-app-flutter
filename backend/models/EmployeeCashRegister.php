<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "employee_cash_register".
 *
 * @property int $employee_id
 * @property int $cash_register_id
 *
 * @property CashRegisters $cashRegister
 * @property Employees $employee
 */
class EmployeeCashRegister extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'employee_cash_register';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['employee_id', 'cash_register_id'], 'required'],
            [['employee_id', 'cash_register_id'], 'integer'],
            [['employee_id', 'cash_register_id'], 'unique', 'targetAttribute' => ['employee_id', 'cash_register_id']],
            [['employee_id'], 'exist', 'skipOnError' => true, 'targetClass' => Employees::class, 'targetAttribute' => ['employee_id' => 'id']],
            [['cash_register_id'], 'exist', 'skipOnError' => true, 'targetClass' => CashRegisters::class, 'targetAttribute' => ['cash_register_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'employee_id' => 'Employee ID',
            'cash_register_id' => 'Cash Register ID',
        ];
    }

    /**
     * Gets query for [[CashRegister]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getCashRegister()
    {
        return $this->hasOne(CashRegisters::class, ['id' => 'cash_register_id']);
    }

    /**
     * Gets query for [[Employee]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getEmployee()
    {
        return $this->hasOne(Employees::class, ['id' => 'employee_id']);
    }

}
