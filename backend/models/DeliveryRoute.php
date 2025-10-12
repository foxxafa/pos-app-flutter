<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "delivery_route".
 *
 * @property int $id
 * @property string|null $prev_stop
 * @property string|null $next_stop
 * @property int $delivery_id
 *
 * @property Delivery $delivery
 */
class DeliveryRoute extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'delivery_route';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['prev_stop', 'next_stop'], 'default', 'value' => null],
            [['delivery_id'], 'required'],
            [['delivery_id'], 'integer'],
            [['prev_stop',  'next_stop'], 'string', 'max' => 20],
            [['delivery_id'], 'exist', 'skipOnError' => true, 'targetClass' => Delivery::class, 'targetAttribute' => ['delivery_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'prev_stop' => 'Previous Stop',
            'next_stop' => 'Next Stop',
            'delivery_id' => 'Delivery ID',
        ];
    }

    /**
     * Gets query for [[Delivery]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getDelivery()
    {
        return $this->hasOne(Delivery::class, ['id' => 'delivery_id']);
    }

}
