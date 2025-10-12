<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "delivery".
 *
 * @property int $id
 * @property string $plaka
 * @property string $driver_id
 * @property string $date
 * @property string $status
 *
 * @property DeliveryRoute[] $deliveryRoutes
 */
class Delivery extends \yii\db\ActiveRecord
{
    const STATUS_WAITING = '0';
    const STATUS_FINISHED = '1';


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'delivery';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['plaka', 'date', 'status'], 'required'],
            [['date'], 'safe'],
            [['driver_id'], 'integer'],
            [['plaka'], 'string', 'max' => 11],
            [['status'], 'string', 'max' => 100],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'plaka' => 'Licence Plate',
            'driver_id' => 'Driver',
            'date' => 'Date',
            'status' => 'Status',
        ];
    }

    /**
     * Gets query for [[DeliveryRoutes]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getDeliveryRoutes()
    {
        return $this->hasMany(DeliveryRoute::class, ['delivery_id' => 'id']);
    }

    public function getStatusLabel(): string
    {
        switch ($this->status) {
            case self::STATUS_FINISHED:
                return 'Finished';
            case self::STATUS_WAITING:
            default:
                return 'Waiting';
        }
    }

}
