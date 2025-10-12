<?php

namespace app\models;

use Yii;
use yii\behaviors\TimestampBehavior;
use yii\db\Expression;

/**
 * This is the model class for table "user_grid_view_preferences".
 *
 * @property int $id
 * @property int $employee_id
 * @property int $grid_view_column_id
 * @property int $is_visible
 * @property int|null $created_at
 * @property int|null $updated_at
 *
 * @property GridViewColumn $gridViewColumn
 * @property Employees $user
 */
class UserGridViewPreference extends \yii\db\ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'user_grid_view_preferences';
    }

    /**
     * {@inheritdoc}
     */
    public function behaviors()
    {
        return [
            [
                'class' => TimestampBehavior::class,
                'value' => new Expression('NOW()'),
            ],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['employee_id', 'grid_view_column_id'], 'required'],
            [['employee_id', 'grid_view_column_id'], 'integer'],
            [['is_visible'], 'boolean'],
            [['is_visible'], 'default', 'value' => true],
            [['employee_id', 'grid_view_column_id'], 'unique', 'targetAttribute' => ['employee_id', 'grid_view_column_id']],
            [['grid_view_column_id'], 'exist', 'skipOnError' => true, 'targetClass' => GridViewColumn::class, 'targetAttribute' => ['grid_view_column_id' => 'id']],
            [['employee_id'], 'exist', 'skipOnError' => true, 'targetClass' => Employees::class, 'targetAttribute' => ['employee_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'employee_id' => 'User ID',
            'grid_view_column_id' => 'Grid View Column ID',
            'is_visible' => 'Is Visible',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }

    /**
     * Gets query for [[GridViewColumn]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getGridViewColumn()
    {
        return $this->hasOne(GridViewColumn::class, ['id' => 'grid_view_column_id']);
    }

    /**
     * Gets query for [[User]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getUser()
    {
        return $this->hasOne(Employees::class, ['id' => 'employee_id']);
    }
} 